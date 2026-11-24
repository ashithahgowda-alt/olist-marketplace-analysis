-- 00_setup_and_checks.sql
-- Project 1: Olist marketplace (SQLite)
-- Sections 1 to 4 were run once after importing the CSVs. Kept as a record only.
-- Do not re-run them.

-- 1. Rename imported tables to short names
ALTER TABLE olist_orders_dataset RENAME TO orders;
ALTER TABLE olist_customers_dataset RENAME TO customers;
ALTER TABLE olist_order_items_dataset RENAME TO order_items;
ALTER TABLE olist_order_payments_dataset RENAME TO order_payments;
ALTER TABLE olist_order_reviews_dataset RENAME TO order_reviews;
ALTER TABLE olist_products_dataset RENAME TO products;
ALTER TABLE olist_sellers_dataset RENAME TO sellers;
ALTER TABLE product_category_name_translation RENAME TO category_translation;

-- 2. Remove duplicate rows caused by importing twice (keep newest copy per key)
DELETE FROM customers WHERE rowid NOT IN
  (SELECT MAX(rowid) FROM customers GROUP BY customer_id);
DELETE FROM order_items WHERE rowid NOT IN
  (SELECT MAX(rowid) FROM order_items GROUP BY order_id, order_item_id);
DELETE FROM order_payments WHERE rowid NOT IN
  (SELECT MAX(rowid) FROM order_payments GROUP BY order_id, payment_sequential);
DELETE FROM order_reviews WHERE rowid NOT IN
  (SELECT MAX(rowid) FROM order_reviews GROUP BY review_id, order_id);

-- 3. Remove malformed review rows from the failed first import
DELETE FROM order_reviews
WHERE length(review_id) <> 32 OR length(order_id) <> 32
   OR review_score IS NULL OR review_score NOT IN (1,2,3,4,5)
   OR length(review_creation_date) <> 19;

-- 4. Convert blank text to real NULLs
UPDATE orders SET order_approved_at = NULL WHERE order_approved_at = '';
UPDATE orders SET order_delivered_carrier_date = NULL WHERE order_delivered_carrier_date = '';
UPDATE orders SET order_delivered_customer_date = NULL WHERE order_delivered_customer_date = '';
UPDATE order_reviews SET review_comment_title = NULL WHERE review_comment_title = '';
UPDATE order_reviews SET review_comment_message = NULL WHERE review_comment_message = '';
UPDATE products SET product_category_name = NULL WHERE product_category_name = '';
UPDATE products SET product_name_lenght = NULL WHERE product_name_lenght = '';
UPDATE products SET product_description_lenght = NULL WHERE product_description_lenght = '';
UPDATE products SET product_photos_qty = NULL WHERE product_photos_qty = '';
UPDATE products SET product_weight_g = NULL WHERE product_weight_g = '';
UPDATE products SET product_length_cm = NULL WHERE product_length_cm = '';
UPDATE products SET product_height_cm = NULL WHERE product_height_cm = '';
UPDATE products SET product_width_cm = NULL WHERE product_width_cm = '';

-- 5. CHECKS (safe to re-run any time)

-- Q1: row counts. Expected: 99441, 112650, 103886, 99224, 99441, 32951, 3095
SELECT 'orders' AS table_name, COUNT(*) AS n FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews
UNION ALL SELECT 'customers',      COUNT(*) FROM customers
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'sellers',        COUNT(*) FROM sellers;

-- C6: numeric columns stored as numbers (expect real or integer, never text)
SELECT 'price' AS col, typeof(price) AS type, COUNT(*) AS n FROM order_items GROUP BY 2
UNION ALL SELECT 'freight_value', typeof(freight_value), COUNT(*) FROM order_items GROUP BY 2
UNION ALL SELECT 'payment_value', typeof(payment_value), COUNT(*) FROM order_payments GROUP BY 2
UNION ALL SELECT 'review_score', typeof(review_score), COUNT(*) FROM order_reviews GROUP BY 2;

-- Blank values are real NULLs. Expected: 160, 1783, 2965, 87656, 58247, 610, 2
SELECT
  (SELECT COUNT(*) FROM orders WHERE order_approved_at IS NULL) AS approved,
  (SELECT COUNT(*) FROM orders WHERE order_delivered_carrier_date IS NULL) AS carrier,
  (SELECT COUNT(*) FROM orders WHERE order_delivered_customer_date IS NULL) AS delivered,
  (SELECT COUNT(*) FROM order_reviews WHERE review_comment_title IS NULL) AS title,
  (SELECT COUNT(*) FROM order_reviews WHERE review_comment_message IS NULL) AS message,
  (SELECT COUNT(*) FROM products WHERE product_category_name IS NULL) AS category,
  (SELECT COUNT(*) FROM products WHERE product_weight_g IS NULL) AS weight;