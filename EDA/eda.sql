
/*
======================================================================
                **E-COMMERCE ANALYTICS – FULL SQL EDA SCRIPT**
----------------------------------------------------------------------
 Recruiter‑Friendly Version with:
   ✔ Structured Comments
   ✔ Clean Indentation
   ✔ Explanations of Logic
   ✔ Expected Outcomes (high‑level)
----------------------------------------------------------------------
 This script performs full-scale EDA across a star-schema warehouse:
   • DIM tables → customers, orders, products, sellers
   • FACT tables → order_items, payments, reviews
   • Cross-table analytics → CLV, category insights, seller performance
======================================================================
*/


/*
=========================================
  COMPREHENSIVE E-COMMERCE DATA ANALYSIS
=========================================
This script performs exploratory data analysis (EDA) across multiple
dimensions and fact tables in an e-commerce database.

Expected Outcomes:
1. Customer segmentation by geography and behavior
2. Order patterns and delivery performance metrics
3. Product and category performance analysis
4. Seller performance and distribution insights
5. Payment and review behavior patterns
6. Trend analysis over time
7. Advanced cross-table insights for business intelligence
*/

-- =================================================================
-- SECTION 1: INITIAL DATA EXPLORATION & TABLE OVERVIEW
-- =================================================================

/*
Objective: Understand dataset structure and basic metrics
Expected: Row counts, column counts, and data quality assessment
*/

-- Check table sizes and structure
WITH table_list AS (
    SELECT table_name
    FROM (VALUES 
        ('dim_sellers'),
        ('dim_products'), 
        ('dim_customers'),
        ('dim_orders'),
        ('fact_order_items'),
        ('fact_reviews'),
        ('fact_payments')
    ) AS t(table_name)
)

SELECT 
    t.table_name,
    r.row_count,
    c.column_count
FROM table_list t
LEFT JOIN (
    SELECT 
        table_name,
        CASE table_name
            WHEN 'dim_sellers' THEN (SELECT COUNT(*) FROM gold_BE.dim_sellers)
            WHEN 'dim_products' THEN (SELECT COUNT(*) FROM gold_BE.dim_products)
            WHEN 'dim_customers' THEN (SELECT COUNT(*) FROM gold_BE.dim_customers)
            WHEN 'dim_orders' THEN (SELECT COUNT(*) FROM gold_BE.dim_orders)
            WHEN 'fact_order_items' THEN (SELECT COUNT(*) FROM gold_BE.fact_order_items)
            WHEN 'fact_reviews' THEN (SELECT COUNT(*) FROM gold_BE.fact_reviews)
            WHEN 'fact_payments' THEN (SELECT COUNT(*) FROM gold_BE.fact_payments)
        END AS row_count
    FROM table_list
) r ON t.table_name = r.table_name
LEFT JOIN (
    SELECT TABLE_NAME AS table_name, COUNT(*) AS column_count
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME IN (SELECT table_name FROM table_list)
    GROUP BY TABLE_NAME
) c ON t.table_name = c.table_name;

-- =================================================================
-- SECTION 2: CUSTOMER ANALYSIS (DIM_CUSTOMERS)
-- =================================================================

/*
Objective: Analyze customer distribution and behavior patterns
Expected: Geographic concentration, customer counts, and segmentation
*/

-- Unique customer count (Total customer base)
SELECT DISTINCT COUNT(customer_custome_key) AS total_customers 
FROM gold_BE.dim_customers;

-- Top 10 cities/states by customer concentration
-- Expected: Identify key markets for marketing focus
SELECT TOP 10
    customer_city,
    customer_state,
    COUNT(*) AS customer_count_by_city_state
FROM gold_BE.dim_customers 
GROUP BY customer_city, customer_state
ORDER BY COUNT(*) DESC;

-- Customer distribution by ZIP code (Geographic density)
SELECT TOP 10
    customer_city,
    customer_zip_code, 
    COUNT(customer_custome_key) AS customer_count
FROM gold_BE.dim_customers
GROUP BY customer_city, customer_zip_code
ORDER BY COUNT(customer_custome_key) DESC;

-- New vs Returning customers based on order frequency
WITH order_count AS (
    SELECT 
        c.customer_custome_key,
        COUNT(o.order_custome_id) AS total_order_count
    FROM gold_BE.dim_customers c  
    LEFT JOIN gold_BE.dim_orders o   
    ON c.customer_custome_key = o.customer_custome_key
    GROUP BY c.customer_custome_key
), classified AS (
    SELECT
        customer_custome_key,
        total_order_count, 
        CASE 
            WHEN total_order_count = 1 THEN 'New Customer'
            WHEN total_order_count > 1 THEN 'Returning Customer'
            ELSE 'No orders'
        END AS customer_type
    FROM order_count
)
SELECT
    customer_type,
    COUNT(customer_type) AS type_count
FROM classified
GROUP BY customer_type;

-- =================================================================
-- SECTION 3: ORDER ANALYSIS (DIM_ORDERS)
-- =================================================================

/*
Objective: Analyze order patterns, status distribution, and delivery performance
Expected: Order trends, delivery efficiency metrics, and status breakdowns
*/

-- Order status distribution (Business health indicator)
SELECT 
    order_status,
    COUNT(*) AS count_status
FROM gold_BE.dim_orders
GROUP BY order_status
ORDER BY count_status DESC;

-- Monthly order trends with running total (Seasonality analysis)
-- Expected: Visualize growth patterns and identify peak seasons
SELECT 
   order_year,
   order_month_s,
   count_order,
   SUM(count_order) OVER(PARTITION BY order_year ORDER BY min_purchase_date) AS running_total 
FROM (
    SELECT  
       YEAR(purchase_date) AS order_year,
       FORMAT(purchase_date, 'y-MMM') AS order_month_s,
       MIN(purchase_date) AS min_purchase_date,
       COUNT(order_custome_id) AS count_order
    FROM gold_BE.dim_orders
    GROUP BY YEAR(purchase_date), FORMAT(purchase_date, 'y-MMM')
) t 
ORDER BY min_purchase_date ASC;

-- Delivery performance analysis (Service quality metric)
-- Expected: Identify on-time vs late delivery percentages
SELECT 
    delivery_mode,
    COUNT(delivery_mode) AS delivery_count
FROM (
    SELECT 
        *,
        CASE 
            WHEN delivered_date > estimated_delivery_date THEN 'Late Delivery'
            ELSE 'On-time Delivery'
        END AS delivery_mode
    FROM gold_BE.dim_orders
) t  
GROUP BY delivery_mode;

-- =================================================================
-- SECTION 4: PRODUCT ANALYSIS (DIM_PRODUCTS)
-- =================================================================

/*
Objective: Analyze product categories, pricing, and inventory structure
Expected: Revenue concentration by category, price range analysis
*/

-- Product category analysis with price distribution
-- Expected: Identify high-value categories and pricing strategies
SELECT
    product_category, 
    MAX(price) AS max_price,
    MIN(price) AS min_price,
    AVG(price) AS avg_price,
    COUNT(*) AS product_count
FROM gold_BE.dim_products
GROUP BY product_category
ORDER BY product_count DESC;

-- =================================================================
-- SECTION 5: SELLER ANALYSIS (DIM_SELLERS)
-- =================================================================

/*
Objective: Evaluate seller distribution, performance, and contribution
Expected: Top performing sellers, geographic seller concentration
*/

-- Seller geographic distribution (Marketplace diversity)
SELECT 
    seller_state,
    COUNT(seller_custome_key) AS seller_count_by_state
FROM gold_BE.dim_sellers
GROUP BY seller_state
ORDER BY seller_count_by_state DESC;

-- Seller performance metrics (Revenue contribution analysis)
SELECT TOP 10
    oi.seller_custome_key,
    SUM(oi.total_order_cost) AS total_revenue,
    COUNT(oi.order_custome_id) AS total_orders,
    AVG(oi.total_order_cost) AS avg_order_value
FROM gold_BE.fact_order_items oi
GROUP BY oi.seller_custome_key
ORDER BY total_revenue DESC;

-- =================================================================
-- SECTION 6: ORDER ITEMS ANALYSIS (FACT_ORDER_ITEMS)
-- =================================================================

/*
Objective: Detailed transaction analysis and revenue insights
Expected: Sales patterns, product performance, and order value metrics
*/

-- Total sales revenue (Key business metric)
SELECT SUM(total_order_cost) AS total_sales 
FROM gold_BE.fact_order_items;

-- Top categories by revenue (Product strategy insights)
-- Expected: Identify most profitable product categories
SELECT TOP 10
    p.product_category,
    p.category_english_name,
    SUM(oi.total_order_cost) AS total_revenue
FROM gold_BE.fact_order_items oi  
LEFT JOIN gold_BE.dim_products p  
ON p.product_custome_key = oi.product_custome_key
GROUP BY p.product_category, p.category_english_name
ORDER BY total_revenue DESC;

-- Highest priced items per order (Premium product analysis)
-- Expected: Identify high-value transactions and premium offerings
SELECT 
    oi.order_id,
    oi.product_id,
    oi.item_price
FROM gold_BE.fact_order_items oi  
WHERE oi.item_price = (
    SELECT MAX(item_price)
    FROM gold_BE.fact_order_items
    WHERE order_id = oi.order_id
)
ORDER BY oi.item_price DESC;

-- =================================================================
-- SECTION 7: PAYMENT ANALYSIS (FACT_PAYMENTS)
-- =================================================================

/*
Objective: Analyze payment behavior and revenue by payment method
Expected: Payment method preferences, customer payment patterns
*/

-- Payment method distribution and revenue contribution
-- Expected: Identify popular payment methods for UX optimization
SELECT
    payment_type,
    COUNT(*) AS transaction_count,
    SUM(payment_value) AS total_revenue
FROM gold_BE.fact_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- Customers using multiple payment methods (Payment flexibility analysis)
SELECT *
FROM (
    SELECT
        customer_custome_key,
        payment_type,
        COUNT(*) OVER (PARTITION BY customer_custome_key) AS payment_methods_count
    FROM (
        SELECT 
            customer_custome_key, 
            payment_type
        FROM gold_BE.fact_payments
        GROUP BY customer_custome_key, payment_type
    ) AS distinct_pairs
) t
WHERE payment_methods_count > 1;

-- =================================================================
-- SECTION 8: REVIEW ANALYSIS (FACT_REVIEWS)
-- =================================================================

/*
Objective: Analyze customer satisfaction and feedback patterns
Expected: Review score distribution, seller performance ratings
*/

-- Review score distribution (Customer satisfaction metric)
-- Expected: Overall satisfaction level and areas for improvement
SELECT 
    review_score, 
    COUNT(*) AS review_count,
    CAST((COUNT(*) * 100.0 / SUM(COUNT(*)) OVER()) AS DECIMAL(5,2)) AS percentage
FROM gold_BE.fact_reviews
GROUP BY review_score
ORDER BY review_count DESC;

-- Relationship between delivery time and review scores
-- Expected: Quantify impact of delivery speed on customer satisfaction
SELECT 
    delivery_duration,
    COUNT(delivery_duration) AS order_count,
    CAST(AVG(CAST(review_score AS DECIMAL(10,2))) AS DECIMAL(10,2)) AS avg_review_score
FROM (
    SELECT 
        r.*, 
        oi.delivery_duration 
    FROM gold_BE.fact_reviews r  
    LEFT JOIN gold_BE.fact_order_items oi  
    ON oi.order_custome_id = r.order_custome_id
) t 
WHERE delivery_duration IS NOT NULL
GROUP BY delivery_duration
ORDER BY order_count DESC;

-- =================================================================
-- SECTION 9: CROSS-TABLE ADVANCED ANALYSIS
-- =================================================================

/*
Objective: Integrated insights combining multiple business dimensions
Expected: Customer lifetime value, behavioral segmentation, and performance correlations
*/

-- Customer Lifetime Value (CLV) Analysis
-- Expected: Identify high-value customers for retention strategies
SELECT 
    o.customer_custome_key AS customer_key,
    SUM(oi.total_order_cost) AS lifetime_value,
    COUNT(DISTINCT o.order_custome_id) AS total_orders,
    CAST(AVG(oi.total_order_cost) as DECIMAL(10,2)) AS avg_order_value
FROM gold_BE.dim_orders o    
LEFT JOIN gold_BE.fact_order_items oi  
ON oi.order_custome_id = o.order_custome_id
GROUP BY o.customer_custome_key
ORDER BY lifetime_value DESC;

-- Top 5% Loyal Customers (VIP Identification)
-- Expected: Segment for loyalty programs and personalized marketing
WITH customer_orders AS (
    SELECT
        customer_custome_key,
        COUNT(order_custome_id) AS lifetime_orders 
    FROM gold_BE.dim_orders
    GROUP BY customer_custome_key
), top_customers AS (
    SELECT 
        customer_custome_key,
        lifetime_orders,
        NTILE(20) OVER(ORDER BY lifetime_orders DESC) AS percentile_rank
    FROM customer_orders
)
SELECT * FROM top_customers
WHERE percentile_rank = 1
ORDER BY lifetime_orders DESC;

-- Product Size vs Delivery Time Analysis
-- Expected: Understand logistics constraints and optimize shipping
WITH item_shipping AS (
    SELECT
        p.product_custome_key,
        o.order_custome_id,
        p.product_weight,
        (p.product_height * p.product_length * p.product_width) AS product_volume,
        o.delivery_duration
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_orders o   
    ON oi.order_custome_id = o.order_custome_id
    LEFT JOIN gold_BE.dim_products p 
    ON p.product_custome_key = oi.product_custome_key
), size_category AS (
    SELECT *,
        CASE 
            WHEN product_weight < 500 AND product_volume < 5000 THEN 'LIGHT'
            WHEN product_weight BETWEEN 500 AND 1000 AND product_volume < 10000 THEN 'MEDIUM' 
            ELSE 'HEAVY'
        END AS size_category
    FROM item_shipping 
)
SELECT 
    size_category, 
    AVG(CAST(delivery_duration AS DECIMAL(10, 2))) AS avg_delivery_days,
    COUNT(*) AS item_count
FROM size_category 
GROUP BY size_category
ORDER BY avg_delivery_days DESC;

-- =================================================================
-- SECTION 10: TIME SERIES TREND ANALYSIS
-- =================================================================

/*
Objective: Identify temporal patterns and business growth trends
Expected: Monthly performance metrics for strategic planning
*/

-- Monthly Revenue Trend (Business growth tracking)
SELECT  
    FORMAT(purchase_date, 'yyyy-MM') AS month_year,
    SUM(total_order_cost) AS monthly_revenue,
    COUNT(DISTINCT order_custome_id) AS monthly_orders,
    AVG(total_order_cost) AS avg_order_value
FROM gold_BE.fact_order_items
WHERE purchase_date IS NOT NULL
GROUP BY FORMAT(purchase_date, 'yyyy-MM')
ORDER BY month_year DESC;

-- Monthly New Customers (Acquisition tracking)
SELECT  
    FORMAT(first_purchase_date, 'yyyy-MM') AS acquisition_month,
    COUNT(customer_custome_key) AS new_customers
FROM (
    SELECT 
        customer_custome_key,
        MIN(purchase_date) AS first_purchase_date
    FROM gold_BE.dim_orders
    GROUP BY customer_custome_key
) t
GROUP BY FORMAT(first_purchase_date, 'yyyy-MM')
ORDER BY acquisition_month DESC;

-- =================================================================
-- SECTION 11: ADVANCED ANALYTICAL QUERIES
-- =================================================================

/*
Objective: Complex business intelligence queries for strategic insights
Expected: Actionable insights for business optimization
*/

-- Top 10 Customers by Total Spend (VIP Identification)
SELECT TOP 10
    c.customer_custome_key,
    c.customer_city,
    c.customer_state,
    SUM(oi.total_order_cost) AS total_spend,
    COUNT(DISTINCT o.order_custome_id) AS order_count
FROM gold_BE.dim_customers c
LEFT JOIN gold_BE.dim_orders o ON c.customer_custome_key = o.customer_custome_key
LEFT JOIN gold_BE.fact_order_items oi ON o.order_custome_id = oi.order_custome_id
GROUP BY c.customer_custome_key, c.customer_city, c.customer_state
ORDER BY total_spend DESC;

-- Highest Revenue Month for Each Category (Seasonal Analysis)
WITH category_monthly AS (
    SELECT
        p.product_category,
        FORMAT(oi.purchase_date, 'yyyy-MM') AS month_year,
        SUM(oi.total_order_cost) AS monthly_revenue,
        ROW_NUMBER() OVER(PARTITION BY p.product_category ORDER BY SUM(oi.total_order_cost) DESC) AS rank
    FROM gold_BE.fact_order_items oi
    LEFT JOIN gold_BE.dim_products p ON oi.product_custome_key = p.product_custome_key
    WHERE oi.purchase_date IS NOT NULL
    GROUP BY p.product_category, FORMAT(oi.purchase_date, 'yyyy-MM')
)
SELECT 
    product_category,
    month_year,
    monthly_revenue
FROM category_monthly
WHERE rank = 1
ORDER BY monthly_revenue DESC;

-- Orders with Multiple Sellers (Complex transactions)
SELECT
    order_custome_id,
    COUNT(DISTINCT seller_custome_key) AS seller_count,
    SUM(total_order_cost) AS order_value
FROM gold_BE.fact_order_items
WHERE order_custome_id IS NOT NULL
GROUP BY order_custome_id
HAVING COUNT(DISTINCT seller_custome_key) > 1
ORDER BY seller_count DESC;

-- =================================================================
-- SECTION 12: DATA QUALITY AND ANOMALY DETECTION
-- =================================================================

/*
Objective: Identify data inconsistencies and potential issues
Expected: Data quality assessment for reliable analytics
*/

-- Missing Critical Data Points
SELECT 
    'Orders without delivery date' AS issue_type,
    COUNT(*) AS issue_count
FROM gold_BE.dim_orders
WHERE delivered_date IS NULL

UNION ALL

SELECT 
    'Products without category',
    COUNT(*) 
FROM gold_BE.dim_products
WHERE product_category IS NULL

UNION ALL

SELECT 
    'Customers without geographic data',
    COUNT(*) 
FROM gold_BE.dim_customers
WHERE customer_city IS NULL OR customer_state IS NULL;

-- Price Anomaly Detection (Potential data errors)
SELECT 
    product_custome_key,
    item_price,
    order_quantity,
    total_order_cost,
    'Potential price anomaly' AS flag
FROM gold_BE.fact_order_items
WHERE item_price <= 0 
   OR total_order_cost <= 0 
   OR item_price > 10000  -- Adjust threshold based on business context
   OR total_order_cost/item_price != order_quantity;

-- Delivery Time Outliers (Extreme cases)
SELECT 
    order_custome_id,
    purchase_date,
    delivered_date,
    delivery_duration,
    'Extreme delivery time' AS flag
FROM gold_BE.dim_orders
WHERE delivery_duration < 0 
   OR delivery_duration > 60;  -- More than 60 days potentially problematic


