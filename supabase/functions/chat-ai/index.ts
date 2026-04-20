import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_KEY = Deno.env.get("GROQ_API_KEY")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  try {
    const { message, history, user_id } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch all data in parallel
    const [
      itemsRes,
      categoriesRes,
      unitsRes,
      lowStockRes,
      outOfStockRes,
      recentMovementsRes,
      stockInRes,
      stockOutRes,
      adjustmentsRes,
      profileRes,
      unreadNotificationsRes,
      topValueItemsRes,
      mostMovedRes,
    ] = await Promise.all([
      // All active items with full details
      supabase
        .from("items")
        .select("name, sku, description, current_stock, opening_stock, low_stock_alert, purchase_price, sales_price, is_active, created_at, categories(name), units(name, abbreviation)")
        .eq("user_id", user_id)
        .eq("is_active", true)
        .order("name")
        .limit(100),

      // All categories
      supabase
        .from("categories")
        .select("name, description, is_default, created_at")
        .eq("user_id", user_id)
        .order("name"),

      // All units
      supabase
        .from("units")
        .select("name, abbreviation")
        .order("name"),

      // Low stock items (current <= alert threshold)
      supabase
        .from("items")
        .select("name, current_stock, low_stock_alert, purchase_price, units(abbreviation)")
        .eq("user_id", user_id)
        .eq("is_active", true)
        .not("low_stock_alert", "is", null)
        .filter("current_stock", "lte", "low_stock_alert")
        .order("current_stock"),

      // Out of stock items (current_stock = 0)
      supabase
        .from("items")
        .select("name, purchase_price, units(abbreviation)")
        .eq("user_id", user_id)
        .eq("is_active", true)
        .eq("current_stock", 0),

      // Recent 20 stock movements
      supabase
        .from("stock_movements")
        .select("movement_type, quantity, stock_before, stock_after, notes, reference, created_at, movement_date, items(name)")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(20),

      // Total stock IN this month
      supabase
        .from("stock_movements")
        .select("quantity")
        .eq("user_id", user_id)
        .eq("movement_type", "IN")
        .eq("fiscal_month", new Date().getMonth() + 1)
        .eq("fiscal_year", new Date().getFullYear()),

      // Total stock OUT this month
      supabase
        .from("stock_movements")
        .select("quantity")
        .eq("user_id", user_id)
        .eq("movement_type", "OUT")
        .eq("fiscal_month", new Date().getMonth() + 1)
        .eq("fiscal_year", new Date().getFullYear()),

      // Adjustments this month
      supabase
        .from("stock_movements")
        .select("quantity, notes, items(name)")
        .eq("user_id", user_id)
        .eq("movement_type", "ADJUSTMENT")
        .eq("fiscal_month", new Date().getMonth() + 1)
        .eq("fiscal_year", new Date().getFullYear()),

      // User profile
      supabase
        .from("profiles")
        .select("email, username, created_at")
        .eq("id", user_id)
        .single(),

      // Unread notifications count
      supabase
        .from("notifications")
        .select("title, body, sent_at")
        .eq("user_id", user_id)
        .eq("read", false)
        .order("sent_at", { ascending: false })
        .limit(5),

      // Top 5 items by inventory value (current_stock * purchase_price)
      supabase
        .from("items")
        .select("name, current_stock, purchase_price, sales_price, units(abbreviation)")
        .eq("user_id", user_id)
        .eq("is_active", true)
        .order("purchase_price", { ascending: false })
        .limit(5),

      // Most moved items (by total movements count) — approximate via recent movements
      supabase
        .from("stock_movements")
        .select("items(name), movement_type, quantity")
        .eq("user_id", user_id)
        .order("created_at", { ascending: false })
        .limit(50),
    ]);

    const items = itemsRes.data ?? [];
    const categories = categoriesRes.data ?? [];
    const units = unitsRes.data ?? [];
    const lowStockItems = lowStockRes.data ?? [];
    const outOfStockItems = outOfStockRes.data ?? [];
    const recentMovements = recentMovementsRes.data ?? [];
    const stockInThisMonth = (stockInRes.data ?? []).reduce((sum: number, r: any) => sum + Number(r.quantity), 0);
    const stockOutThisMonth = (stockOutRes.data ?? []).reduce((sum: number, r: any) => sum + Number(r.quantity), 0);
    const adjustments = adjustmentsRes.data ?? [];
    const profile = profileRes.data;
    const unreadNotifications = unreadNotificationsRes.data ?? [];
    const topValueItems = topValueItemsRes.data ?? [];
    const allRecentMoves = mostMovedRes.data ?? [];

    // Calculate inventory value
    const totalInventoryValue = items.reduce((sum: number, i: any) =>
      sum + (Number(i.current_stock) * Number(i.purchase_price)), 0);
    const totalSalesValue = items.reduce((sum: number, i: any) =>
      sum + (Number(i.current_stock) * Number(i.sales_price)), 0);
    const potentialProfit = totalSalesValue - totalInventoryValue;

    // Find most moved items
    const moveCount: Record<string, number> = {};
    allRecentMoves.forEach((m: any) => {
      const name = m.items?.name ?? "Unknown";
      moveCount[name] = (moveCount[name] ?? 0) + 1;
    });
    const mostMoved = Object.entries(moveCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([name, count]) => `${name} (${count} movements)`);

    const systemPrompt = `You are an intelligent AI assistant embedded in an Inventory Management System (IMS). You have real-time access to the user's inventory data and can provide deep insights.

## USER PROFILE
- Name: ${profile?.username ?? "Unknown"}
- Email: ${profile?.email ?? "Unknown"}
- Member since: ${profile ? new Date(profile.created_at).toLocaleDateString() : "Unknown"}

## DATABASE SCHEMA (for reference)

### items
- Tracks all inventory products
- Fields: name, sku, description, current_stock, opening_stock, low_stock_alert, purchase_price, sales_price, is_active
- Linked to: categories, units

### categories  
- Groups items into logical categories
- Fields: name, description, is_default

### units
- Units of measurement for items
- Fields: name, abbreviation (e.g. kg, pcs, ltr)

### stock_movements
- Full audit trail of every stock change
- movement_type: IN (stock received), OUT (stock dispatched), ADJUSTMENT (manual correction)
- Fields: quantity, stock_before, stock_after, notes, reference, movement_date, fiscal_year, fiscal_month

### notifications
- System alerts sent to the user (e.g. low stock alerts)

## LIVE INVENTORY SNAPSHOT

### Summary
- Total active items: ${items.length}
- Total categories: ${categories.length}
- Items out of stock: ${outOfStockItems.length}
- Items below alert threshold: ${lowStockItems.length}
- Unread notifications: ${unreadNotifications.length}

### Financial Overview
- Total inventory cost value: ₹${totalInventoryValue.toFixed(2)}
- Total inventory sales value: ₹${totalSalesValue.toFixed(2)}
- Potential gross profit: ₹${potentialProfit.toFixed(2)}

### This Month's Activity (${new Date().toLocaleString('default', { month: 'long', year: 'numeric' })})
- Total stock received (IN): ${stockInThisMonth} units
- Total stock dispatched (OUT): ${stockOutThisMonth} units
- Adjustments made: ${adjustments.length}
${adjustments.length > 0 ? adjustments.map((a: any) => `  • ${a.items?.name}: ${a.quantity} units — ${a.notes ?? "no notes"}`).join("\n") : ""}

### All Active Items (${items.length} total)
${items.length > 0 ? items.map((i: any) =>
  `- ${i.name}${i.sku ? ` [SKU: ${i.sku}]` : ""} | Category: ${i.categories?.name ?? "N/A"} | Stock: ${i.current_stock} ${i.units?.abbreviation ?? ""} | Alert at: ${i.low_stock_alert ?? "not set"} | Buy: ₹${i.purchase_price} | Sell: ₹${i.sales_price} | Margin: ₹${(Number(i.sales_price) - Number(i.purchase_price)).toFixed(2)}`
).join("\n") : "No active items."}

### Categories (${categories.length} total)
${categories.length > 0 ? categories.map((c: any) =>
  `- ${c.name}${c.is_default ? " [default]" : ""}${c.description ? `: ${c.description}` : ""}`
).join("\n") : "No categories."}

### Units of Measurement
${units.length > 0 ? units.map((u: any) => `- ${u.name} (${u.abbreviation})`).join("\n") : "No units."}

### Out of Stock Items (${outOfStockItems.length})
${outOfStockItems.length > 0 ? outOfStockItems.map((i: any) =>
  `- ${i.name} | Buy price: ₹${i.purchase_price} | Unit: ${i.units?.abbreviation ?? "N/A"}`
).join("\n") : "No items are out of stock."}

### Low Stock Alerts (${lowStockItems.length} items need attention)
${lowStockItems.length > 0 ? lowStockItems.map((i: any) =>
  `- ${i.name}: current=${i.current_stock} ${i.units?.abbreviation ?? ""}, reorder at=${i.low_stock_alert} | Buy price: ₹${i.purchase_price}`
).join("\n") : "All items are sufficiently stocked."}

### Top 5 Items by Purchase Price
${topValueItems.length > 0 ? topValueItems.map((i: any) =>
  `- ${i.name}: stock=${i.current_stock} ${i.units?.abbreviation ?? ""} | Value in stock: ₹${(Number(i.current_stock) * Number(i.purchase_price)).toFixed(2)} | Margin: ₹${(Number(i.sales_price) - Number(i.purchase_price)).toFixed(2)}`
).join("\n") : "No data."}

### Most Active Items (by recent movement count)
${mostMoved.length > 0 ? mostMoved.map(m => `- ${m}`).join("\n") : "No movement data."}

### Recent Stock Movements (last 20)
${recentMovements.length > 0 ? recentMovements.map((m: any) =>
  `- [${m.movement_type}] ${m.items?.name ?? "Unknown"}: ${m.quantity} units | Before: ${m.stock_before} → After: ${m.stock_after} | ${m.notes ?? "no notes"}${m.reference ? ` | Ref: ${m.reference}` : ""} | ${new Date(m.created_at).toLocaleDateString()}`
).join("\n") : "No recent movements."}

### Unread Notifications (${unreadNotifications.length})
${unreadNotifications.length > 0 ? unreadNotifications.map((n: any) =>
  `- ${n.title}: ${n.body} (${new Date(n.sent_at).toLocaleDateString()})`
).join("\n") : "No unread notifications."}

## YOUR CAPABILITIES
You can answer questions like:
- "Which items are running low?" → use low stock data
- "What is my total inventory value?" → use financial overview
- "Which items haven't moved recently?" → compare items vs movements
- "What's my profit margin on X?" → calculate from buy/sell prices
- "How much stock did I receive this month?" → use monthly activity
- "Which items are out of stock?" → use out of stock list
- "What are my most active items?" → use most moved list
- "Do I have any unread alerts?" → use notifications
- "What categories do I have?" → use categories list
- "Give me a full inventory report" → summarize all sections

## RULES
- Always use the live data above — never make up numbers
- Be concise but complete
- Use ₹ for currency
- If asked something outside available data, say so honestly
- Give actionable suggestions where relevant (e.g. "consider reordering X")
- Format responses clearly with bullet points or sections when listing data`;

    const messages = [
      { role: "system", content: systemPrompt },
      ...(history || []),
      { role: "user", content: message },
    ];

    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: messages,
        temperature: 0.3,
        max_tokens: 1024,
      }),
    });

    const data = await response.json();
    const reply = data.choices?.[0]?.message?.content ?? "No response";

    return new Response(JSON.stringify({ reply }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
    });
  }
});
