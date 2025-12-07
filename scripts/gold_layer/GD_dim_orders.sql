/********************************************************************************************
DIMENSION TABLE: gold_BE.dim_orders
Purpose:
- Create an Order Dimension Table for star-schema warehouse design.
- Enrich order records with related customer address fields and calculated metrics.
- Helps BI tools analyze orders by:
    ✔ Delivery performance
    ✔ Order trends by month/year
    ✔ Customer behavior indicators

Expected Outcome:
- Each row represents a unique order.
- Connects to fact tables via `order_custome_id`
********************************************************************************************/

-- Drop existing view if already exists
IF OBJECT_ID('gold_BE.dim_orders','V') IS NOT NULL
    DROP VIEW gold_BE.dim_orders;
GO


-- Create the Dimension View
CREATE VIEW gold_BE.dim_orders AS 
SELECT 
    -- Surrogate Key (Used as primary join key for facts)
    ROW_NUMBER() OVER(ORDER BY o.order_id) AS order_custome_id,

    -- Natural Keys
    o.order_id,

    -- Customer Surrogate Key
    c.customer_custome_key,

    -- Order dates
    CAST(o.order_purchase_timestamp AS DATE) AS purchase_date,
    o.order_status,
    CAST(o.order_delivered_customer_date AS DATE) AS delivered_date,
    CAST(o.order_estimated_delivery_date AS DATE) AS estimated_delivery_date,

    -- Delivery metric (Days it took to deliver)
    DATEDIFF(
        DAY,
        CAST(o.order_purchase_timestamp AS DATE),
        CAST(o.order_delivered_customer_date AS DATE)
    ) AS delivery_duration,

    -- Customer delivery location details
    c.customer_zip_code AS customer_address_zip,
    c.customer_city AS delivered_city,
    c.customer_state AS delivered_state,

    -- Calendar fields for reporting
    YEAR(o.order_purchase_timestamp) AS order_year,
    FORMAT(o.order_purchase_timestamp, 'MMM') AS order_month

FROM silver_BE.olist_orders_dataset o 
LEFT JOIN gold_BE.dim_customers c 
    ON o.customer_id = c.customer_id
WHERE o.order_purchase_timestamp IS NOT NULL;
GO


-- Check the data
SELECT * FROM gold_BE.dim_orders





-- IF OBJECT_ID('gold_BE.dim_orders','V') IS NOT NULL
--     DROP VIEW gold_BE.dim_orders
-- GO

-- CREATE VIEW gold_BE.dim_orders AS 
-- SELECT 
--     ROW_NUMBER() OVER(ORDER BY o.order_id) as order_custome_id,
--     o.order_id,
--     c.customer_id,
--     CAST(o.order_purchase_timestamp AS DATE) as purchase_date,
--     o.order_status,
--     CAST(o.order_delivered_customer_date AS DATE) as delivered_date,
--     DATEDIFF(DAY,CAST(o.order_purchase_timestamp AS DATE), CAST(o.order_delivered_customer_date AS DATE)) as delivery_duration,
--     c.customer_zip_code as customer_address_zip,
--     c.customer_city as delivered_city,
--     c.customer_state as delivered_state,
--     YEAR(o.order_purchase_timestamp) as order_year,
--     FORMAT(o.order_purchase_timestamp,'MMM') as order_month
-- FROM silver_BE.olist_orders_dataset o 
-- LEFT JOIN gold_BE.dim_customers c 
-- ON o.customer_id = c.customer_id
-- WHERE o.order_purchase_timestamp IS NOT NULL
-- GO