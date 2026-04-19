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

    // Create Supabase client with service role to fetch live data
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Fetch live data for this user
    const [itemsRes, categoriesRes, lowStockRes, recentMovementsRes] = await Promise.all([
      supabase.from("items").select("name, current_stock, low_stock_alert, purchase_price, sales_price, is_active").eq("user_id", user_id).eq("is_active", true).limit(50),
      supabase.from("categories").select("name, description").eq("user_id", user_id).limit(20),
      supabase.from("items").select("name, current_stock, low_stock_alert").eq("user_id", user_id).eq("is_active", true).not("low_stock_alert", "is", null).filter("current_stock", "lte", "low_stock_alert").limit(10),
      supabase.from("stock_movements").select("movement_type, quantity, notes, created_at, items(name)").eq("user_id", user_id).order("created_at", { ascending: false }).limit(10),
    ]);

    const items = itemsRes.data ?? [];
    const categories = categoriesRes.data ?? [];
    const lowStockItems = lowStockRes.data ?? [];
    const recentMovements = recentMovementsRes.data ?? [];

    const systemPrompt = `You are an intelligent AI assistant for an Inventory Management System (IMS). You have full knowledge of the user's database schema and live data.

## DATABASE SCHEMA

### categories
- id, user_id, name, description, is_default, created_at, updated_at
- Stores product categories created by each user

### items
- id, user_id, category_id, unit_id
- name, description, sku
- opening_stock, current_stock, low_stock_alert
- purchase_price, sales_price
- is_active, created_at, updated_at
- Each item belongs to a category and a unit of measurement

### units
- id, name, abbreviation, created_by, created_at, updated_at
- Units of measurement (e.g. kg, pcs, liters)

### stock_movements
- id, item_id, user_id, movement_type (IN/OUT/ADJUSTMENT)
- quantity, stock_before, stock_after
- notes, reference, created_at
- movement_date, movement_time, fiscal_year, fiscal_month
- Records every stock change with full audit trail

### profiles
- id, email, username, created_at
- User profile linked to auth.users

### notifications
- id, user_id, title, body, data, read, sent_at
- In-app notifications for the user

## LIVE DATA (right now for this user)

### Active Items (${items.length} total):
${items.length > 0 ? items.map(i => `- ${i.name}: stock=${i.current_stock}, alert_at=${i.low_stock_alert ?? "none"}, buy=₹${i.purchase_price}, sell=₹${i.sales_price}`).join("\n") : "No active items found."}

### Categories (${categories.length} total):
${categories.length > 0 ? categories.map(c => `- ${c.name}${c.description ? `: ${c.description}` : ""}`).join("\n") : "No categories found."}

### Low Stock Alerts (${lowStockItems.length} items):
${lowStockItems.length > 0 ? lowStockItems.map(i => `- ${i.name}: current=${i.current_stock}, threshold=${i.low_stock_alert}`).join("\n") : "No low stock items right now."}

### Recent Stock Movements (last 10):
${recentMovements.length > 0 ? recentMovements.map(m => `- ${(m.items as any)?.name ?? "Unknown"}: ${m.movement_type} ${m.quantity} — ${m.notes ?? "no notes"} (${new Date(m.created_at).toLocaleDateString()})`).join("\n") : "No recent movements."}

## YOUR ROLE
- Answer questions about the user's inventory using the live data above
- Help interpret stock levels, movements, and trends
- Give actionable advice (reorder suggestions, pricing insights, etc.)
- Be concise and helpful
- If asked about something not in the live data, say you can only see the data snapshot from this session
- Do NOT make up data that isn't shown above`;

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
