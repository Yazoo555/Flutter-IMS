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
] = await Promise.all([
supabase
.from("items")
.select("name, sku, description, current_stock, opening_stock, low_stock_alert, purchase_price, sales_price, is_active, created_at, categories(name), units(name, abbreviation)")
.eq("user_id", user_id)
.eq("is_active", true)
.order("name")
.limit(100),

supabase
.from("categories")
.select("name, description, is_default, created_at")
.eq("user_id", user_id)
.order("name"),

supabase
.from("units")
.select("name, abbreviation")
.order("name"),

supabase
.from("items")
.select("name, current_stock, low_stock_alert, purchase_price, units(abbreviation)")
.eq("user_id", user_id)
.eq("is_active", true)
.not("low_stock_alert", "is", null)
.filter("current_stock", "lte", "low_stock_alert")
.order("current_stock"),

supabase
.from("items")
.select("name, purchase_price, units(abbreviation)")
.eq("user_id", user_id)
.eq("is_active", true)
.eq("current_stock", 0),

supabase
.from("stock_movements")
.select("movement_type, quantity, stock_before, stock_after, notes, reference, created_at, movement_date, items(name)")
.eq("user_id", user_id)
.order("created_at", { ascending: false })
.limit(20),

supabase
.from("stock_movements")
.select("quantity")
.eq("user_id", user_id)
.eq("movement_type", "IN")
.eq("fiscal_month", new Date().getMonth() + 1)
.eq("fiscal_year", new Date().getFullYear()),

supabase
.from("stock_movements")
.select("quantity")
.eq("user_id", user_id)
.eq("movement_type", "OUT")
.eq("fiscal_month", new Date().getMonth() + 1)
.eq("fiscal_year", new Date().getFullYear()),

supabase
.from("stock_movements")
.select("quantity, notes, items(name)")
.eq("user_id", user_id)
.eq("movement_type", "ADJUSTMENT")
.eq("fiscal_month", new Date().getMonth() + 1)
.eq("fiscal_year", new Date().getFullYear()),

supabase
.from("profiles")
.select("email, username, created_at")
.eq("id", user_id)
.single(),

supabase
.from("notifications")
.select("title, body, sent_at")
.eq("user_id", user_id)
.eq("read", false)
.order("sent_at", { ascending: false })
.limit(5),

supabase
.from("items")
.select("name, current_stock, purchase_price, sales_price, units(abbreviation)")
.eq("user_id", user_id)
.eq("is_active", true)
.order("purchase_price", { ascending: false })
.limit(5),

supabase
.from("stock_movements")
.select("items(name), movement_type, quantity")
.eq("user_id", user_id)
.order("created_at", { ascending: false })
.limit(50),

// Suppliers
supabase
.from("suppliers")
.select("name, email, phone, contact_person, notes, created_at")
.eq("user_id", user_id)
.order("name"),

// Logistics tasks with items
supabase
.from("logistics_tasks_detail")
.select("*")
.eq("user_id", user_id)
.order("created_at", { ascending: false })
.limit(20),
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
const suppliers = suppliersRes.data ?? [];
const logisticsTasks = logisticsTasksRes.data ?? [];

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

// Logistics breakdown by status
const pendingTasks = logisticsTasks.filter((t: any) => t.status === 'pending');
const inProgressTasks = logisticsTasks.filter((t: any) => t.status === 'in_progress');
const completedTasks = logisticsTasks.filter((t: any) => t.status === 'completed');
const cancelledTasks = logisticsTasks.filter((t: any) => t.status === 'cancelled');

const systemPrompt = `You are Aria, an intelligent AI assistant built into an Inventory Management System (IMS). You have real-time access to the user's complete business data.

CRITICAL FORMATTING RULES — follow these without exception:
- Never use markdown headers like ### or ## or #
- Never use horizontal rules like --- or ***
- Never use bold markdown like **text** or __text__
- Use plain conversational sentences and short paragraphs
- When listing items, use simple numbered lines like "1. Item name" or clean bullet points with just "•"
- Separate sections with a single blank line only
- Keep responses concise — get to the point fast
- Use Npr Rs for all currency values
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

RECENT MOVEMENTS (last 20):
${recentMovements.map((m: any) =>
`[${m.movement_type}] ${m.items?.name ?? "Unknown"}: ${m.quantity} units | ${m.stock_before} → ${m.stock_after} | ${m.notes ?? "no notes"}${m.reference ? " | ref: " + m.reference : ""} | ${new Date(m.created_at).toLocaleDateString()}`
).join("\n")}

UNREAD NOTIFICATIONS (${unreadNotifications.length}):
${unreadNotifications.length > 0 ? unreadNotifications.map((n: any) => `${n.title}: ${n.body}`).join("\n") : "None"}

SUPPLIERS (${suppliers.length}):
${suppliers.length > 0 ? suppliers.map((s: any) =>
`${s.name}${s.contact_person ? " | contact: " + s.contact_person : ""}${s.phone ? " | phone: " + s.phone : ""}${s.email ? " | email: " + s.email : ""}${s.notes ? " | notes: " + s.notes : ""}`
).join("\n") : "No suppliers added yet"}

LOGISTICS TASKS (${logisticsTasks.length} total):
Pending: ${pendingTasks.length} | In Progress: ${inProgressTasks.length} | Completed: ${completedTasks.length} | Cancelled: ${cancelledTasks.length}

${logisticsTasks.length > 0 ? logisticsTasks.map((t: any) => {
const itemList = Array.isArray(t.items) && t.items.length > 0
? t.items.map((i: any) => `${i.name} x${i.quantity} ${i.unit ?? ""}`).join(", ")
: "no items";
return `[${t.status.toUpperCase()}] "${t.title}" | supplier: ${t.supplier_name}${t.scheduled_date ? " | due: " + t.scheduled_date : ""} | items: ${itemList}${t.notes ? " | notes: " + t.notes : ""}`;
}).join("\n") : "No logistics tasks yet"}

SCHEMA KNOWLEDGE:
- stock_movements.movement_type can be: IN (stock received), OUT (stock dispatched), ADJUSTMENT (manual correction), or custom types like "sale"
- logistics_status transitions: pending → in_progress → completed, pending → cancelled, in_progress → cancelled
- Each logistics task can carry multiple items via logistics_task_items
- Suppliers are linked to logistics tasks; each task has one supplier

WHAT YOU CAN DO:
Answer questions about stock levels, financial overview, profit margins, movement history, supplier details, logistics status, low stock alerts, category breakdowns, and monthly activity. Give actionable business advice based on the data. If something isn't in the data above, say so honestly without guessing.`;

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
