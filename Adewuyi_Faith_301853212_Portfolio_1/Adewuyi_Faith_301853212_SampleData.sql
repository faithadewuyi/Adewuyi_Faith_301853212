 Portfolio 1
-- Sample Data


INSERT INTO customers (full_name, phone, email)
VALUES
    ('Amina Bello', '08030000001', 'amina@example.com'),
    ('David Okafor', '08030000002', 'david@example.com'),
    ('Grace Adeyemi', '08030000003', 'grace@example.com');


-- Insert sample products
INSERT INTO products
    (product_name, category, unit_price, quantity_in_stock)
VALUES
    ('Crate of Eggs', 'eggs', 4500.00, 100),
    ('Day-Old Chicks', 'poultry', 1200.00, 200),
    ('Layer Feed 25kg', 'feed', 18000.00, 50),
    ('Broiler Chicken', 'poultry', 8500.00, 40);


-- Create a paid sale for Amina Bello
INSERT INTO sales (customer_id, payment_status)
SELECT customer_id, 'paid'
FROM customers
WHERE email = 'amina@example.com';


-- Create a pending sale for David Okafor
INSERT INTO sales (customer_id, payment_status)
SELECT customer_id, 'pending'
FROM customers
WHERE email = 'david@example.com';


-- Add Crate of Eggs to Amina's sale
INSERT INTO sale_items
    (sale_id, product_id, quantity, unit_price_at_sale)
SELECT s.sale_id, p.product_id, 2, 4500.00
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN products p ON p.product_name = 'Crate of Eggs'
WHERE c.email = 'amina@example.com'
  AND s.payment_status = 'paid';


-- Add Layer Feed to David's sale
INSERT INTO sale_items
    (sale_id, product_id, quantity, unit_price_at_sale)
SELECT s.sale_id, p.product_id, 1, 18000.00
FROM sales s
JOIN customers c ON c.customer_id = s.customer_id
JOIN products p ON p.product_name = 'Layer Feed 25kg'
WHERE c.email = 'david@example.com'
  AND s.payment_status = 'pending';