
-- Abitim Farms: Portfolio 1


CREATE TABLE customers (
    customer_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(150) UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE products (
    product_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(30) NOT NULL
        CHECK (category IN ('eggs', 'poultry', 'feed', 'other')),
    unit_price NUMERIC(12, 2) NOT NULL
        CHECK (unit_price >= 0),
    quantity_in_stock INTEGER NOT NULL DEFAULT 0
        CHECK (quantity_in_stock >= 0)
);

CREATE TABLE sales (
    sale_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id INTEGER NOT NULL
        REFERENCES customers(customer_id),
    sale_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending'
        CHECK (payment_status IN ('pending', 'paid', 'cancelled'))
);

CREATE TABLE sale_items (
    sale_item_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sale_id INTEGER NOT NULL
        REFERENCES sales(sale_id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL
        REFERENCES products(product_id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_at_sale NUMERIC(12, 2) NOT NULL
        CHECK (unit_price_at_sale >= 0)
);
