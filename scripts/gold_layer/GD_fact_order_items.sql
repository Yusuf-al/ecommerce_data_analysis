/********************************************************************************************
FACT TABLE: gold_BE.fact_order_items
Purpose:
- Creates a Fact Table to store measurable metrics from each order-item line.
- Combines order item details with dimension keys from products, sellers, and orders.
- Allows reporting on sales, cost, margins, delivery performance, etc.

Expected Outcome:
- Each row represents a single item in an order (order line level).
- Can be connected to dimension tables for BI dashboards and analysis.

********************************************************************************************/

-- Drop existing VIEW if already exists
IF OBJECT_ID('gold_BE.fact_order_items','V') IS NOT NULL
    DROP VIEW gold_BE.fact_order_items;
GO


-- Create the Fact View
CREATE VIEW gold_BE.fact_order_items AS
SELECT 
    -- Surrogate key (unique row number for the fact table)
    ROW_NUMBER() OVER (ORDER BY oi.order_id, oi.product_id) AS order_item_key,

    -- Natural keys from transaction tables
    oi.order_id,
    oi.product_id,
    oi.seller_id,

    /* Foreign Keys linking to Dimension Tables:
       Allow star-schema joins for analysis */
    odr.order_custome_id,
    p.product_custome_key,
    s.seller_custome_key,

    /* Fact Metrics
       These are measurable numerical values used in reporting */
    CAST(oi.price AS DECIMAL(10,2)) AS item_price,
    oi.order_item_id AS order_quantity,  -- Not actual ID, represents quantity
    CAST(oi.price * oi.order_item_id AS DECIMAL(12,2)) AS total_order_cost,
    oi.freight_value AS shipping_cost,

    /* Date & Order Performance Metrics
       Support delivery analytics & monthly/yearly trends */
    odr.purchase_date,
    odr.order_status,
    odr.delivered_date,
    odr.delivery_duration,
    odr.order_month,
    odr.order_year

FROM silver_BE.olist_order_items_dataset oi
LEFT JOIN gold_BE.dim_products p  
    ON oi.product_id = p.product_id 
LEFT JOIN gold_BE.dim_orders odr  
    ON oi.order_id = odr.order_id
LEFT JOIN gold_BE.dim_sellers s  
    ON oi.seller_id = s.seller_id
;
GO

-- Review Data
SELECT * 
FROM gold_BE.fact_order_items;








































    -- SELECT 
    --     oi.order_id as oi_id,
    --     p.product_id p_id,
    --     p.product_category,
    --     oi.price,
    --     oi.order_item_id as order_quantity,
    --     oi.price * oi.order_item_id as total_order_cost,
    --     odr.purchase_date as purchase_date,
    --     odr.delivered_date,
    --     odr.delivery_duration,
    --     odr.order_month,
    --     odr.order_year,
    --     oi.freight_value as shippig_cost,
    --     odr.customer_address_zip,
    --     odr.delivered_city,
    --     odr.delivered_state,
    --     s.seller_id as seller_id
    -- FROM silver_BE.olist_order_items_dataset oi
    -- LEFT JOIN gold_BE.dim_products p  
    -- ON oi.product_id = p.product_id 
    -- LEFT JOIN gold_BE.dim_orders odr  
    -- ON oi.order_id = odr.order_id
    -- LEFT JOIN gold_BE.dim_sellers s  
    -- ON oi.seller_id = s.seller_id



-- SELECT 
-- product_id,
-- price,
-- freight_value, 
-- COUNT(*) OVER(PARTITION BY product_id,price) as COUNT
-- FROM silver_BE.olist_order_items_dataset


-- SELECT oi_s_id,
--     COUNT(*)
-- FROM (

-- SELECT 
-- oi.seller_id as oi_s_id,
-- s.seller_id as s_s_id
-- FROM silver_BE.olist_order_items_dataset oi
-- LEFT JOIN gold_BE.dim_sellers s  
-- ON oi.seller_id = s.seller_id
-- )t GROUP BY oi_s_id 
-- ORDER BY COUNT(*) DESC

-- SELECT COUNT(*) from gold_BE.dim_sellers
    
 






-- SELECT DISTINCT oi.product_id
-- FROM silver_BE.olist_order_items_dataset oi
-- LEFT JOIN gold_BE.dim_products dp
--     ON oi.product_id = dp.product_id
-- WHERE dp.product_id IS NULL;



-- SELECT
--     mp.product_id,
--     COALESCE(i.inferred_category, 'unknown') AS product_category_name,
--     mp.price,
--     mp.freight_value
-- FROM (
--     SELECT DISTINCT oi.product_id, oi.price, oi.freight_value
--     FROM silver_BE.olist_order_items_dataset oi
--     LEFT JOIN gold_BE.dim_products dp
--         ON oi.product_id = dp.product_id
--     WHERE dp.product_id IS NULL
-- ) mp
-- LEFT JOIN (
--     SELECT
--         oi2.product_id,
--         oi2.price,
--         oi2.freight_value,
--         MAX(dp2.product_category_name) AS inferred_category
--     FROM silver_BE.olist_order_items_dataset oi2
--     LEFT JOIN silver_BE.olist_products_dataset dp2
--         ON oi2.product_id = dp2.product_id
--     WHERE dp2.product_category_name IS NOT NULL
--     GROUP BY
--         oi2.product_id,
--         oi2.price,
--         oi2.freight_value
-- ) i
-- ON  mp.product_id = i.product_id
-- AND mp.price = i.price
-- AND mp.freight_value = i.freight_value;


-- WITH missing_products AS (
--     /* All product_ids missing from dimension */
--     SELECT DISTINCT oi.product_id, oi.price, oi.freight_value
--     FROM silver_BE.olist_order_items_dataset oi
--     LEFT JOIN gold_BE.dim_products dp
--         ON oi.product_id = dp.product_id
--     WHERE dp.product_id IS NULL
-- ),

-- inferred AS (
--     /* Inferred categories from similar price + freight_value rows */
--     SELECT
--         oi2.product_id,
--         oi2.price,
--         oi2.freight_value,
--         MAX(dp2.product_category_name) AS inferred_category
--     FROM silver_BE.olist_order_items_dataset oi2
--     LEFT JOIN silver_BE.olist_products_dataset dp2
--         ON oi2.product_id = dp2.product_id
--     WHERE dp2.product_category_name IS NOT NULL
--     GROUP BY
--         oi2.product_id,
--         oi2.price,
--         oi2.freight_value
-- )

-- SELECT
--     mp.product_id,
--     COALESCE(i.inferred_category, 'unknown') AS product_category_name,
--     mp.price,
--     mp.freight_value
-- FROM missing_products mp
-- LEFT JOIN inferred i
--     ON mp.product_id = i.product_id
--     AND mp.price = i.price
--     AND mp.freight_value = i.freight_value;
-- GO