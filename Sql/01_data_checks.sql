-- C1: duplicate orders (expect 0)
-- C1: Result 0. No duplicate order IDs, so orders has one row per order.
SELECT COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_orders
FROM orders;

-- C2: orders that have no item rows, by status
-- C2: Result 775 (unavailable 603, canceled 164, created 5, invoiced 2, shipped 1). These orders have no items, so item-based revenue leaves them out.
SELECT o.order_status, COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status;

-- C3: how many reviews does each order have?
-- C3: Result 0 to 3 reviews per order (98,126 have exactly 1). I average reviews per order before joining, to avoid double counting.
SELECT n_reviews, COUNT(*) AS orders
FROM (SELECT o.order_id, COUNT(r.review_id) AS n_reviews
      FROM orders o
      LEFT JOIN order_reviews r ON r.order_id = o.order_id
      GROUP BY o.order_id)
GROUP BY n_reviews
ORDER BY n_reviews;

-- C4: delivered orders with no delivery date
-- C4: Result 8. Eight delivered orders have no delivery date, so I exclude them from delivery-time measures.
SELECT COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'delivered'
  AND (order_delivered_customer_date IS NULL OR order_delivered_customer_date = '');

-- C5: orders per month, to spot partial months
-- C5: Result 25 months, Sep 2016 to Oct 2018. The first and last months are partial, so trends use full months only.
SELECT strftime('%Y-%m', order_purchase_timestamp) AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY month
ORDER BY month;

-- C6: did prices import as numbers? (expect real)
-- C6: Result real for all 112,650 prices. Prices are stored as numbers.
SELECT typeof(price) AS price_type, COUNT(*) AS n
FROM order_items
GROUP BY price_type;