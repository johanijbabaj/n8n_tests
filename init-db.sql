-- Database Initialization Script for Analytics Chatbot
-- Creates sample e-commerce database with customers, products, and orders

-- Create tables
CREATE TABLE IF NOT EXISTS customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    region VARCHAR(50) NOT NULL,
    signup_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) DEFAULT 'completed',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample customers
INSERT INTO customers (name, email, region, signup_date) VALUES
('Alice Johnson', 'alice.johnson@example.com', 'North America', '2024-01-15'),
('Bob Smith', 'bob.smith@example.com', 'Europe', '2024-02-20'),
('Carol White', 'carol.white@example.com', 'Asia', '2024-01-10'),
('David Brown', 'david.brown@example.com', 'North America', '2024-03-05'),
('Emma Davis', 'emma.davis@example.com', 'Europe', '2024-02-14'),
('Frank Wilson', 'frank.wilson@example.com', 'Asia', '2024-04-01'),
('Grace Lee', 'grace.lee@example.com', 'North America', '2024-01-25'),
('Henry Miller', 'henry.miller@example.com', 'Europe', '2024-03-10'),
('Iris Taylor', 'iris.taylor@example.com', 'Asia', '2024-02-05'),
('Jack Anderson', 'jack.anderson@example.com', 'North America', '2024-04-15'),
('Kate Thomas', 'kate.thomas@example.com', 'Europe', '2024-01-30'),
('Liam Martinez', 'liam.martinez@example.com', 'Asia', '2024-03-20'),
('Mia Garcia', 'mia.garcia@example.com', 'North America', '2024-02-25'),
('Noah Rodriguez', 'noah.rodriguez@example.com', 'Europe', '2024-04-10'),
('Olivia Hernandez', 'olivia.hernandez@example.com', 'Asia', '2024-01-05'),
('Paul Lopez', 'paul.lopez@example.com', 'North America', '2024-03-15'),
('Quinn Gonzalez', 'quinn.gonzalez@example.com', 'Europe', '2024-02-28'),
('Rachel Wilson', 'rachel.wilson@example.com', 'Asia', '2024-04-05'),
('Sam Moore', 'sam.moore@example.com', 'North America', '2024-01-20'),
('Tina Jackson', 'tina.jackson@example.com', 'Europe', '2024-03-25');

-- Insert sample products
INSERT INTO products (name, category, price) VALUES
('Laptop Pro 15', 'Electronics', 1299.99),
('Wireless Mouse', 'Electronics', 29.99),
('USB-C Cable', 'Accessories', 19.99),
('Mechanical Keyboard', 'Electronics', 149.99),
('27" Monitor', 'Electronics', 399.99),
('Desk Lamp', 'Office', 49.99),
('Office Chair', 'Furniture', 299.99),
('Standing Desk', 'Furniture', 599.99),
('Notebook Set', 'Office', 15.99),
('Pen Collection', 'Office', 12.99),
('Webcam HD', 'Electronics', 89.99),
('Headphones Pro', 'Electronics', 199.99),
('Phone Stand', 'Accessories', 24.99),
('Cable Organizer', 'Accessories', 9.99),
('Laptop Sleeve', 'Accessories', 34.99),
('External SSD 1TB', 'Electronics', 149.99),
('Wireless Charger', 'Electronics', 39.99),
('Desk Mat', 'Office', 29.99),
('Monitor Arm', 'Accessories', 79.99),
('LED Strip Lights', 'Office', 25.99),
('Smart Speaker', 'Electronics', 99.99),
('Tablet 10"', 'Electronics', 449.99),
('Smartwatch', 'Electronics', 299.99),
('Fitness Tracker', 'Electronics', 79.99),
('Portable Charger', 'Accessories', 44.99),
('Document Scanner', 'Office', 249.99),
('Label Maker', 'Office', 59.99),
('Whiteboard', 'Office', 89.99),
('Desk Organizer', 'Office', 34.99),
('Plant Pot', 'Office', 19.99);

-- Insert sample orders (500+ orders spanning several months)
INSERT INTO orders (customer_id, product_id, quantity, order_date, total_amount, status)
SELECT
    (random() * 19 + 1)::int as customer_id,
    (random() * 29 + 1)::int as product_id,
    (random() * 3 + 1)::int as quantity,
    CURRENT_DATE - (random() * 180)::int as order_date,
    (random() * 500 + 20)::decimal(10,2) as total_amount,
    CASE
        WHEN random() < 0.9 THEN 'completed'
        WHEN random() < 0.95 THEN 'pending'
        ELSE 'cancelled'
    END as status
FROM generate_series(1, 500);

-- Update total_amount to match actual product prices
UPDATE orders o
SET total_amount = o.quantity * p.price
FROM products p
WHERE o.product_id = p.id;

-- Create useful views for analysis
CREATE VIEW sales_summary AS
SELECT
    DATE_TRUNC('month', order_date) as month,
    COUNT(*) as total_orders,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_order_value,
    COUNT(DISTINCT customer_id) as unique_customers
FROM orders
WHERE status = 'completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month DESC;

CREATE VIEW top_products AS
SELECT
    p.id,
    p.name,
    p.category,
    p.price,
    COUNT(o.id) as times_ordered,
    SUM(o.quantity) as total_quantity_sold,
    SUM(o.total_amount) as total_revenue
FROM products p
LEFT JOIN orders o ON p.id = o.product_id AND o.status = 'completed'
GROUP BY p.id, p.name, p.category, p.price
ORDER BY total_revenue DESC;

CREATE VIEW customer_analytics AS
SELECT
    c.id,
    c.name,
    c.email,
    c.region,
    c.signup_date,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
GROUP BY c.id, c.name, c.email, c.region, c.signup_date
ORDER BY lifetime_value DESC;

CREATE VIEW regional_performance AS
SELECT
    c.region,
    COUNT(DISTINCT c.id) as total_customers,
    COUNT(o.id) as total_orders,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id AND o.status = 'completed'
GROUP BY c.region
ORDER BY total_revenue DESC;

-- Create indexes for better query performance
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_product_id ON orders(product_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_customers_region ON customers(region);
CREATE INDEX idx_products_category ON products(category);

-- Grant permissions (optional, for n8n database user)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO n8n_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO n8n_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO n8n_user;

-- Display summary statistics
DO $$
BEGIN
    RAISE NOTICE '=== Database Initialization Complete ===';
    RAISE NOTICE 'Total Customers: %', (SELECT COUNT(*) FROM customers);
    RAISE NOTICE 'Total Products: %', (SELECT COUNT(*) FROM products);
    RAISE NOTICE 'Total Orders: %', (SELECT COUNT(*) FROM orders);
    RAISE NOTICE 'Total Revenue: $%', (SELECT SUM(total_amount) FROM orders WHERE status = 'completed');
    RAISE NOTICE '======================================';
END $$;
