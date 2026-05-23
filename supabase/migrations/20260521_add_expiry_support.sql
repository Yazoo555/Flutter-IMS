-- Add has_expiry column to categories table
ALTER TABLE categories ADD COLUMN IF NOT EXISTS has_expiry BOOLEAN NOT NULL DEFAULT false;

-- Add expiry_date column to items table
ALTER TABLE items ADD COLUMN IF NOT EXISTS expiry_date DATE;

-- Update inventory query view to include category has_expiry and item expiry_date
CREATE OR REPLACE VIEW items_with_categories AS
SELECT 
  i.*,
  c.has_expiry,
  c.name as category_name
FROM items i
JOIN categories c ON c.id = i.category_id;
