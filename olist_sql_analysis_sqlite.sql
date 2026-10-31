/*
VALIDASI DATA 
*/
SELECT order_status, COUNT(*) AS jumlah_order
FROM orders
GROUP BY order_status
ORDER BY jumlah_order DESC;

SELECT 'orders' AS tabel, COUNT(*) AS jumlah_baris FROM orders
UNION ALL SELECT 'order_items',    COUNT(*) FROM order_items
UNION ALL SELECT 'customers',      COUNT(*) FROM customers
UNION ALL SELECT 'products',       COUNT(*) FROM products
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews',  COUNT(*) FROM order_reviews;

SELECT order_id, COUNT(*) AS n
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT
    SUM(order_purchase_timestamp IS NULL)       AS null_purchase_date,
    SUM(order_delivered_customer_date IS NULL)  AS null_delivered_date,
    SUM(order_estimated_delivery_date IS NULL)  AS null_estimated_date
FROM orders;

SELECT COUNT(*) AS order_tanpa_item
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

SELECT o.order_status, COUNT(*) AS order_tanpa_item
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY order_tanpa_item DESC;

/*
KPI UTAMA
*/
SELECT
    COUNT(DISTINCT o.order_id)                           AS total_orders,
    COUNT(DISTINCT c.customer_unique_id)                 AS unique_customers,
    ROUND(SUM(oi.price), 2)                              AS total_revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN customers c    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered';

/*
TREN PENJUALAN
*/
SELECT
    strftime('%Y-%m', o.order_purchase_timestamp) AS bulan,
    COUNT(DISTINCT o.order_id)                     AS total_orders,
    ROUND(SUM(oi.price), 2)                        AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY bulan
ORDER BY bulan;

WITH monthly AS (
    SELECT
        strftime('%Y-%m', o.order_purchase_timestamp) AS bulan,
        SUM(oi.price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY bulan
)
SELECT
    bulan,
    ROUND(revenue, 2) AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY bulan), 2) AS revenue_bulan_lalu,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY bulan))
          / LAG(revenue) OVER (ORDER BY bulan) * 100, 2) AS growth_mom_persen
FROM monthly
ORDER BY bulan;

SELECT date(order_purchase_timestamp) AS tanggal,
       COUNT(DISTINCT order_id) AS total_orders
FROM orders
WHERE order_status = 'delivered'
  AND strftime('%Y-%m', order_purchase_timestamp) = '2017-11'
GROUP BY tanggal
ORDER BY total_orders DESC
LIMIT 5;

/*
MENCARI KATEGORI PRODUK DAN KATEGORI TERATAS
*/
SELECT
    COALESCE(ct.product_category_name_english, 'unknown') AS kategori,
    COUNT(*)                 AS item_terjual,
    ROUND(SUM(oi.price), 2)  AS revenue,
    ROUND(SUM(oi.price) * 100.0 / SUM(SUM(oi.price)) OVER (), 2) AS kontribusi_persen
FROM order_items oi
JOIN orders o             ON oi.order_id = o.order_id
JOIN products p           ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation ct
       ON p.product_category_name = ct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY kategori
ORDER BY revenue DESC
LIMIT 10;

SELECT
    c.customer_city,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city, c.customer_state
ORDER BY total_orders DESC
LIMIT 10;

/*
PENGIRIMAN DAN KEPUASAN PELANGGAN
*/
SELECT
    strftime('%Y', order_purchase_timestamp) AS tahun,
    COUNT(*) AS order_delivered,
    ROUND(AVG(julianday(order_delivered_customer_date)
              - julianday(order_purchase_timestamp)), 2) AS avg_hari_kirim,
    ROUND(SUM(order_delivered_customer_date > order_estimated_delivery_date)
          * 100.0 / COUNT(*), 2) AS persen_terlambat
FROM orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
GROUP BY tahun
ORDER BY tahun;

SELECT
    CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date
         THEN 'Terlambat' ELSE 'Tepat waktu' END AS status_pengiriman,
    COUNT(*)                         AS jumlah_review,
    ROUND(AVG(r.review_score), 2)    AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY status_pengiriman;

SELECT
    c.customer_state,
    COUNT(*) AS total_orders,
    ROUND(SUM(o.order_delivered_customer_date > o.order_estimated_delivery_date)
          * 100.0 / COUNT(*), 2) AS persen_terlambat
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY persen_terlambat DESC
LIMIT 10;

/*
PELANGGAN
*/
WITH cust_orders AS (
    SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS jumlah_order
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_pelanggan,
    SUM(jumlah_order = 1) AS beli_sekali,
    SUM(jumlah_order > 1) AS beli_ulang,
    ROUND(SUM(jumlah_order > 1) * 100.0 / COUNT(*), 2) AS repeat_rate_persen
FROM cust_orders;

WITH base AS (
    SELECT
        c.customer_unique_id,
        MAX(o.order_purchase_timestamp)  AS last_order,
        COUNT(DISTINCT o.order_id)       AS frequency,
        SUM(oi.price)                    AS monetary
    FROM orders o
    JOIN customers c    ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm AS (
    SELECT
        customer_unique_id,
        CAST(julianday((SELECT MAX(order_purchase_timestamp) FROM orders))
             - julianday(last_order) AS INTEGER) AS recency_days,
        frequency,
        monetary,
        NTILE(4) OVER (ORDER BY last_order ASC) AS r_score,
        CASE WHEN frequency >= 3 THEN 3
             WHEN frequency = 2  THEN 2
             ELSE 1 END AS f_score,
        NTILE(4) OVER (ORDER BY monetary ASC)   AS m_score
    FROM base
)
SELECT
    CASE
        WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 3 THEN 'Champions'
        WHEN f_score >= 2                                   THEN 'Loyal / Repeat'
        WHEN r_score >= 3 AND m_score >= 3                  THEN 'Big Spender Baru'
        WHEN r_score <= 2 AND m_score >= 3                  THEN 'At Risk (Big Spender)'
        WHEN r_score >= 3                                   THEN 'Pelanggan Baru'
        ELSE 'Hibernating'
    END AS segmen,
    COUNT(*)                    AS jumlah_pelanggan,
    ROUND(AVG(monetary), 2)     AS avg_monetary,
    ROUND(AVG(recency_days), 0) AS avg_recency_hari
FROM rfm
GROUP BY segmen
ORDER BY jumlah_pelanggan DESC;