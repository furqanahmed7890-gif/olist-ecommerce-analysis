-- Olist marketplace schema: 8 tables with primary and foreign keys.
-- Note: customer_id is one per order; customer_unique_id identifies the actual person.
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, orders, products, sellers, customers, category_translation CASCADE;

CREATE TABLE customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT NOT NULL,
    customer_zip_code_prefix TEXT,
    customer_city            TEXT,
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix TEXT,
    seller_city            TEXT,
    seller_state           CHAR(2)
);

CREATE TABLE category_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT NOT NULL
);

-- No foreign key to category_translation: two categories in the data have no translation.
CREATE TABLE products (
    product_id                 TEXT PRIMARY KEY,
    product_category_name      TEXT,
    product_name_length        INTEGER,
    product_description_length INTEGER,
    product_photos_qty         INTEGER,
    product_weight_g           INTEGER,
    product_length_cm          INTEGER,
    product_height_cm          INTEGER,
    product_width_cm           INTEGER
);

CREATE TABLE orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT NOT NULL REFERENCES customers (customer_id),
    order_status                  TEXT NOT NULL,
    order_purchase_timestamp      TIMESTAMP NOT NULL,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id            TEXT NOT NULL REFERENCES orders (order_id),
    order_item_id       INTEGER NOT NULL,
    product_id          TEXT NOT NULL REFERENCES products (product_id),
    seller_id           TEXT NOT NULL REFERENCES sellers (seller_id),
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10, 2) NOT NULL,
    freight_value       NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             TEXT NOT NULL REFERENCES orders (order_id),
    payment_sequential   INTEGER NOT NULL,
    payment_type         TEXT NOT NULL,
    payment_installments INTEGER,
    payment_value        NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id alone is not unique (the same review can cover several orders), so the key is the pair.
CREATE TABLE order_reviews (
    review_id               TEXT NOT NULL,
    order_id                TEXT NOT NULL REFERENCES orders (order_id),
    review_score            SMALLINT NOT NULL CHECK (review_score BETWEEN 1 AND 5),
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    PRIMARY KEY (review_id, order_id)
);

CREATE INDEX ON customers (customer_unique_id);
CREATE INDEX ON orders (customer_id);
CREATE INDEX ON orders (order_purchase_timestamp);
CREATE INDEX ON order_items (seller_id);
CREATE INDEX ON order_items (product_id);
CREATE INDEX ON order_reviews (order_id);
