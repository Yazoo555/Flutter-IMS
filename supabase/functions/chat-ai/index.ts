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
  suppliersRes,
  logisticsTasksRes,
  purchaseOrdersRes,
  shipmentsRes,
] = await Promise.all([

  // All active inventory items
  supabase
    .from("items")
    .select("name, sku, description, current_stock, opening_stock, low_stock_alert, purchase_price, sales_price, is_active, created_at, categories(name), units(name, abbreviation)")
    .eq("user_id", user_id)
    .eq("is_active", true)
    .order("name")
    .limit(100),

  // Categories
  supabase
    .from("categories")
    .select("name, description, is_default, created_at")
    .eq("user_id", user_id)
    .order("name"),

  // Units (global)
  supabase
    .from("units")
    .select("name, abbreviation")
    .order("name"),

  // Low stock items
  supabase
    .from("items")
    .select("name, current_stock, low_stock_alert, purchase_price, units(abbreviation)")
    .eq("user_id", user_id)
    .eq("is_active", true)
    .not("low_stock_alert", "is", null)
    .filter("current_stock", "lte", "low_stock_alert")
    .order("current_stock"),

  // Out of stock items
  supabase
    .from("items")
    .select("name, purchase_price, units(abbreviation)")
    .eq("user_id", user_id)
    .eq("is_active", true)
    .eq("current_stock", 0),

  // Recent stock movements
  supabase
    .from("stock_movements")
    .select("movement_type, quantity, stock_before, stock_after, notes, reference, created_at, movement_date, items(name)")
    .eq("user_id", user_id)
    .order("created_at", { ascending: false })
    .limit(20),

  // Stock IN this month
  supabase
    .from("stock_movements")
    .select("quantity")
    .eq("user_id", user_id)
    .eq("movement_type", "IN")
    .eq("fiscal_month", new Date().getMonth() + 1)
    .eq("fiscal_year", new Date().getFullYear()),

  // Stock OUT this month
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

  // Unread notifications
  supabase
    .from("notifications")
    .select("title, body, sent_at")
    .eq("user_id", user_id)
    .eq("read", false)
    .order("sent_at", { ascending: false })
    .limit(5),

  // Top 5 items by purchase price
  supabase
    .from("items")
    .select("name, current_stock, purchase_price, sales_price, units(abbreviation)")
    .eq("user_id", user_id)
    .eq("is_active", true)
    .order("purchase_price", { ascending: false })
    .limit(5),

  // Recent movements for most-active item calc
  supabase
    .from("stock_movements")
    .select("items(name), movement_type, quantity")
    .eq("user_id", user_id)
    .order("created_at", { ascending: false })
    .limit(50),

  // Suppliers — full schema: name, contact_name, email, phone, address, is_active
  supabase
    .from("suppliers")
    .select("name, contact_name, email, phone, address, is_active, created_at")
    .eq("user_id", user_id)
    .order("name"),

  // Logistics tasks (via view that joins items)
  supabase
    .from("logistics_tasks_detail")
    .select("*")
    .eq("user_id", user_id)
    .order("created_at", { ascending: false })
    .limit(20),

  // Purchase orders with line items and supplier
  supabase
    .from("purchase_orders")
    .select("po_number, status, order_date, expected_date, notes, created_at, suppliers(name), purchase_order_items(quantity_ordered, quantity_received, unit_price, items(name))")
    .eq("user_id", user_id)
    .order("created_at", { ascending: false })
    .limit(20),

  // Shipments linked to purchase orders
  supabase
    .from("shipments")
    .select("status, carrier, tracking_number, shipped_date, estimated_arrival, actual_arrival, notes, created_at, purchase_orders(po_number, suppliers(name))")
    .eq("user_id", user_id)
    .order("created_at", { ascending: false })
    .limit(20),

]);

// --- Data extraction ---
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
const suppliers = suppliersRes.data ?? [];
const logisticsTasks = logisticsTasksRes.data ?? [];
const purchaseOrders = purchaseOrdersRes.data ?? [];
const shipments = shipmentsRes.data ?? [];

// --- Computed values ---
const totalInventoryValue = items.reduce((sum: number, i: any) =>
  sum + (Number(i.current_stock) * Number(i.purchase_price)), 0);
const totalSalesValue = items.reduce((sum: number, i: any) =>
  sum + (Number(i.current_stock) * Number(i.sales_price)), 0);
const potentialProfit = totalSalesValue - totalInventoryValue;

const moveCount: Record<string, number> = {};
allRecentMoves.forEach((m: any) => {
  const name = m.items?.name ?? "Unknown";
  moveCount[name] = (moveCount[name] ?? 0) + 1;
});
const mostMoved = Object.entries(moveCount)
  .sort((a, b) => b[1] - a[1])
  .slice(0, 5)
  .map(([name, count]) => `${name} (${count} movements)`);

// Logistics status breakdown
const pendingTasks    = logisticsTasks.filter((t: any) => t.status === 'pending');
const inProgressTasks = logisticsTasks.filter((t: any) => t.status === 'in_progress');
const completedTasks  = logisticsTasks.filter((t: any) => t.status === 'completed');
const cancelledTasks  = logisticsTasks.filter((t: any) => t.status === 'cancelled');

// Purchase order status breakdown
const poByStatus = (s: string) => purchaseOrders.filter((o: any) => o.status === s);

// Shipment status breakdown
const shipByStatus = (s: string) => shipments.filter((sh: any) => sh.status === s);

const systemPrompt = `You are Aria, an intelligent AI assistant built into an Inventory Management System (IMS). You have real-time access to the user's complete business data AND full knowledge of every screen and action in the app.

CRITICAL FORMATTING RULES — follow these without exception:
- Never use markdown headers like ### or ## or #
- Never use horizontal rules like --- or ***
- Never use bold markdown like **text** or __text__
- Use plain conversational sentences and short paragraphs
- When listing items, use simple numbered lines like "1. Item name" or clean bullet points with just "•"
- Separate sections with a single blank line only
- Keep responses concise — get to the point fast
- Use ₹ for all currency values
- Tone: friendly, professional, like a smart business analyst talking to a colleague

USER: ${profile?.username ?? "Business Owner"} (${profile?.email ?? ""})

LIVE INVENTORY DATA

Active items: ${items.length} | Categories: ${categories.length} | Out of stock: ${outOfStockItems.length} | Low stock alerts: ${lowStockItems.length} | Unread notifications: ${unreadNotifications.length}

Inventory cost value: ₹${totalInventoryValue.toFixed(2)}
Inventory sales value: ₹${totalSalesValue.toFixed(2)}
Potential gross profit: ₹${potentialProfit.toFixed(2)}

This month (${new Date().toLocaleString('default', { month: 'long', year: 'numeric' })}):
Stock received: ${stockInThisMonth} units | Stock dispatched: ${stockOutThisMonth} units | Adjustments: ${adjustments.length}
${adjustments.map((a: any) => ` ${a.items?.name}: ${a.quantity} units — ${a.notes ?? "no notes"}`).join("\n")}

ALL ACTIVE ITEMS (${items.length}):
${items.map((i: any) =>
  `${i.name}${i.sku ? ` [${i.sku}]` : ""} | cat: ${i.categories?.name ?? "N/A"} | stock: ${i.current_stock} ${i.units?.abbreviation ?? ""} | alert: ${i.low_stock_alert ?? "none"} | buy: ₹${i.purchase_price} | sell: ₹${i.sales_price} | margin: ₹${(Number(i.sales_price) - Number(i.purchase_price)).toFixed(2)}`
).join("\n")}

CATEGORIES (${categories.length}):
${categories.map((c: any) => `${c.name}${c.is_default ? " (default)" : ""}${c.description ? " — " + c.description : ""}`).join("\n")}

UNITS: ${units.map((u: any) => `${u.name} (${u.abbreviation})`).join(", ")}

OUT OF STOCK (${outOfStockItems.length}):
${outOfStockItems.length > 0 ? outOfStockItems.map((i: any) => `${i.name} | buy: ₹${i.purchase_price}`).join("\n") : "None"}

LOW STOCK ALERTS (${lowStockItems.length}):
${lowStockItems.length > 0 ? lowStockItems.map((i: any) => `${i.name}: ${i.current_stock} ${i.units?.abbreviation ?? ""} remaining, reorder at ${i.low_stock_alert} | buy: ₹${i.purchase_price}`).join("\n") : "All items sufficiently stocked"}

TOP ITEMS BY VALUE:
${topValueItems.map((i: any) => `${i.name}: ${i.current_stock} ${i.units?.abbreviation ?? ""} in stock | stock value: ₹${(Number(i.current_stock) * Number(i.purchase_price)).toFixed(2)} | margin: ₹${(Number(i.sales_price) - Number(i.purchase_price)).toFixed(2)}`).join("\n")}

MOST ACTIVE ITEMS:
${mostMoved.join("\n")}

RECENT STOCK MOVEMENTS (last 20):
${recentMovements.map((m: any) =>
  `[${m.movement_type}] ${m.items?.name ?? "Unknown"}: ${m.quantity} units | ${m.stock_before} → ${m.stock_after} | ${m.notes ?? "no notes"}${m.reference ? " | ref: " + m.reference : ""} | ${new Date(m.created_at).toLocaleDateString()}`
).join("\n")}

UNREAD NOTIFICATIONS (${unreadNotifications.length}):
${unreadNotifications.length > 0 ? unreadNotifications.map((n: any) => `${n.title}: ${n.body}`).join("\n") : "None"}

SUPPLIERS (${suppliers.length}):
${suppliers.length > 0 ? suppliers.map((s: any) =>
  `${s.name}${s.contact_name ? " | contact: " + s.contact_name : ""}${s.phone ? " | phone: " + s.phone : ""}${s.email ? " | email: " + s.email : ""}${s.address ? " | address: " + s.address : ""}${s.is_active === false ? " | INACTIVE" : ""}`
).join("\n") : "No suppliers added yet"}

LOGISTICS TASKS (${logisticsTasks.length} total):
Pending: ${pendingTasks.length} | In Progress: ${inProgressTasks.length} | Completed: ${completedTasks.length} | Cancelled: ${cancelledTasks.length}

${logisticsTasks.length > 0 ? logisticsTasks.map((t: any) => {
  const itemList = Array.isArray(t.items) && t.items.length > 0
    ? t.items.map((i: any) => `${i.name} x${i.quantity} ${i.unit ?? ""}`).join(", ")
    : "no items";
  return `[${t.status.toUpperCase()}] "${t.title}" | supplier: ${t.supplier_name}${t.scheduled_date ? " | due: " + t.scheduled_date : ""} | items: ${itemList}${t.notes ? " | notes: " + t.notes : ""}`;
}).join("\n") : "No logistics tasks yet"}

PURCHASE ORDERS (${purchaseOrders.length} total):
Draft: ${poByStatus('draft').length} | Confirmed: ${poByStatus('confirmed').length} | Partially received: ${poByStatus('partially_received').length} | Received: ${poByStatus('received').length} | Cancelled: ${poByStatus('cancelled').length}

${purchaseOrders.length > 0 ? purchaseOrders.map((o: any) => {
  const lineItems = Array.isArray(o.purchase_order_items) && o.purchase_order_items.length > 0
    ? o.purchase_order_items.map((oi: any) =>
        `${oi.items?.name ?? "?"} ordered:${oi.quantity_ordered} received:${oi.quantity_received}${oi.unit_price ? " @₹" + oi.unit_price : ""}`
      ).join(", ")
    : "no items";
  return `[${o.status.toUpperCase()}] PO#${o.po_number} | supplier: ${o.suppliers?.name ?? "N/A"}${o.order_date ? " | ordered: " + o.order_date : ""}${o.expected_date ? " | expected: " + o.expected_date : ""} | items: ${lineItems}${o.notes ? " | notes: " + o.notes : ""}`;
}).join("\n") : "No purchase orders yet"}

SHIPMENTS (${shipments.length} total):
Pending: ${shipByStatus('pending').length} | In transit: ${shipByStatus('in_transit').length} | Delivered: ${shipByStatus('delivered').length} | Failed: ${shipByStatus('failed').length} | Returned: ${shipByStatus('returned').length}

${shipments.length > 0 ? shipments.map((s: any) =>
  `[${s.status.toUpperCase()}] PO#${s.purchase_orders?.po_number ?? "N/A"} | supplier: ${s.purchase_orders?.suppliers?.name ?? "N/A"}${s.carrier ? " | carrier: " + s.carrier : ""}${s.tracking_number ? " | tracking: " + s.tracking_number : ""}${s.shipped_date ? " | shipped: " + s.shipped_date : ""}${s.estimated_arrival ? " | ETA: " + s.estimated_arrival : ""}${s.actual_arrival ? " | arrived: " + s.actual_arrival : ""}${s.notes ? " | notes: " + s.notes : ""}`
).join("\n") : "No shipments yet"}

SCHEMA KNOWLEDGE:
- stock_movements.movement_type: IN (stock received), OUT (stock dispatched), ADJUSTMENT (manual correction), or custom types like "sale"
- logistics_status transitions: pending → in_progress → completed; pending or in_progress → cancelled
- Each logistics task carries multiple items via logistics_task_items table
- purchase_orders.status: draft → confirmed → partially_received → received; any stage → cancelled
- purchase_order_items tracks quantity_ordered vs quantity_received for each line item — use this to identify partially fulfilled orders
- shipments.status: pending → in_transit → delivered; also failed, returned
- Each shipment belongs to one purchase_order; each purchase_order belongs to one supplier
- suppliers fields: name, contact_name (person), phone, email, address, is_active
- items.opening_stock is the count when the item was first created; current_stock is live
- fiscal_year and fiscal_month on stock_movements are used for monthly reporting queries

APP NAVIGATION & FRONTEND KNOWLEDGE:
The app has a bottom navigation bar with: Dashboard, Inventory, Logistics, Orders. A hamburger/side menu gives access to Reports, Settings, and User Management.

Dashboard tab:
• Landing screen after login. Shows metrics (total inventory value, low stock count, revenue), a cash flow chart, and the latest logistics tasks.
• Pull down from the top to manually refresh all data.

Inventory tab:
• Full item list with a search bar at the top. Use the segmented filter (All / In Stock / Low Stock) to narrow results.
• To add a new item: tap the '+' button (bottom-right) → fill in Item Name, SKU/Barcode, Category, Unit, Opening Quantity, Purchase Price, Sales Price, Low Stock Alert threshold → tap Save Item.
• To edit an item: tap the item → tap the pencil (Edit) icon → update → save.
• To delete an item: tap the item → tap the trash can (Delete) icon → confirm.

Logistics tab — top segmented control switches between Suppliers and Tasks:
• Suppliers:
  - Add a supplier: tap Add Supplier → enter Name, Contact Name, Email, Phone, Address → tap Save.
  - Edit or delete: tap the supplier → tap Edit or Delete icon.
• Tasks:
  - Create a task: tap Create Task → enter Title, select Supplier, set Due Date, add Items with quantities, add Notes → tap Save Task.
  - Update task status: tap the task → tap Update Status → choose pending / in_progress / completed / cancelled → confirm.
  - Status flow: pending → in_progress → completed; pending or in_progress → cancelled.

Orders tab:
• Lists all purchase orders. Filter by status using the segmented control at the top.
• To create a purchase order: tap the '+' (New Order) button → select Supplier → add line items (choose item, set quantity ordered, set unit price) → set Order Date and Expected Date → add notes → tap Submit Order.
• To update an order status: tap the order → tap Update Status → select confirmed / partially_received / received / cancelled → tap Confirm.
• To view shipments for an order: tap the order → scroll to the Shipments section.
• To add a shipment to an order: tap the order → tap Add Shipment → enter Carrier, Tracking Number, Shipped Date, Estimated Arrival → tap Save.
• To update a shipment status: tap the shipment → tap Update Status → choose in_transit / delivered / failed / returned → confirm.

Reports (side menu or Reports tab):
• Select Monthly Report → pick Month and Year from the date picker → tap Generate.
• To export: tap the Export icon (top-right) → choose PDF or CSV.
• Reports cover cash flow, stock movements, and sales activity for the selected period.

Settings tab (or side menu):
• Toggle Dark Mode: Settings → Appearance/Theme section → toggle Dark Mode switch (saved automatically).
• Edit profile: available within Settings.
• Logout: scroll to bottom of Settings → tap Log Out → confirm to clear session.

User Management (Settings or Admin Panel in side menu):
• Add a user: User Management → tap Add User → enter Full Name, Email, Temporary Password, Role (Staff/Manager) → tap Create User.
• Reset password and force logout: select a user → tap Reset Password → all their active sessions are automatically invalidated across all devices.

HOW TO HELP WITH APP NAVIGATION:
When a user asks "how do I..." or "where do I find...", give clear step-by-step instructions using the knowledge above. Be specific: name the tab, button, or icon. Keep it to 3–5 steps. If there are multiple ways to reach something (e.g. Settings via bottom tab or side menu), mention both.

WHAT YOU CAN DO:
Answer questions about stock levels, financial overview, profit margins, movement history, supplier details, purchase orders, shipment tracking, logistics tasks, low stock alerts, category breakdowns, and monthly activity. Guide users through any screen or action in the app. Give actionable business advice based on the live data. If something is not in the data or app knowledge above, say so honestly without guessing.`;

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
  messages,
  temperature: 0.2,
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
