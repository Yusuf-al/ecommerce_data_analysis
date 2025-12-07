/********************************************************************************************
FACT TABLE: gold_BE.fact_reviews
Purpose:
- Store customer reviews at the fact level for analytical reporting.
- Connect review data to products, sellers, and orders via dimension keys.
- Enable BI dashboards to analyze:
      ✔ Review scores by product
      ✔ Seller performance
      ✔ Delivery impact on rating

Expected Outcome:
- One row per review.
- Fact table linked to dimensions for star-schema analytics.
********************************************************************************************/

-- Drop existing view if it exists
IF OBJECT_ID('gold_BE.fact_reviews','V') IS NOT NULL
    DROP VIEW gold_BE.fact_reviews;
GO


-- Create the fact view
CREATE VIEW gold_BE.fact_reviews AS

/* STEP 1: Extract required review + basic order information */
WITH base_review AS (
    SELECT 
        rv.review_id,
        rv.order_id,
        rv.review_score,
        rv.review_creation_date,
        
        -- From order items to connect products & sellers
        oi.product_id,
        oi.seller_id,
        
        -- Order attributes for analysis
        od.order_status,
        od.order_delivered_customer_date
    FROM silver_BE.olist_order_reviews_dataset rv
    LEFT JOIN silver_BE.olist_order_items_dataset oi 
        ON rv.order_id = oi.order_id
    LEFT JOIN silver_BE.olist_orders_dataset od
        ON rv.order_id = od.order_id
),

/* STEP 2: Attach Product Dimension Key */
attach_product AS (
    SELECT 
        br.*,
        dp.product_custome_key
    FROM base_review br
    LEFT JOIN gold_BE.dim_products dp
        ON br.product_id = dp.product_id
),

/* STEP 3: Attach Seller Dimension Key */
attach_seller AS (
    SELECT 
        ap.*,
        ds.seller_custome_key
    FROM attach_product ap
    LEFT JOIN gold_BE.dim_sellers ds
        ON ap.seller_id = ds.seller_id
),

/* STEP 4: Attach Order Dimension Key */
attach_order AS (
    SELECT
        asel.*,
        dor.order_custome_id
    FROM attach_seller asel
    LEFT JOIN gold_BE.dim_orders dor
        ON asel.order_id = dor.order_id
)

/* Final Selection */
SELECT
    -- Surrogate key for the fact table
    ROW_NUMBER() OVER (ORDER BY review_id) AS review_custome_key,

    -- Foreign Keys for BI star schema
    order_custome_id,
    product_custome_key,
    seller_custome_key,

    -- Natural keys and attributes
    review_id,
    order_id,
    product_id,
    seller_id,

    review_score,
    CAST(review_creation_date as DATE) as review_creation_date,
    order_status,
    CAST(order_delivered_customer_date as DATE) as delivered_date

FROM attach_order
WHERE product_custome_key IS NOT NULL;  -- Ensure linkable records

GO

-- Display results
SELECT * FROM gold_BE.fact_reviews;





























































-- WITH combine_order_review AS (
--     SELECT 
--         rv.review_id,
--         COALESCE(rv.order_id,oi.order_id) as order_id ,                          -- Single correct order_id
--         rv.review_score,
--         rv.review_creation_date,

--         oi.product_id,
--         oi.seller_id,
--         od.order_status,
--         od.order_delivered_customer_date
--     FROM silver_BE.olist_order_reviews_dataset rv
--     LEFT JOIN silver_BE.olist_order_items_dataset oi  
--         ON rv.order_id = oi.order_id
--     LEFT JOIN silver_BE.olist_orders_dataset od  
--         ON rv.order_id = od.order_id
-- ),

-- connect_product AS (
--     SELECT 
--         cor.review_id,
--         cor.order_id,
--         cor.review_score,
--         cor.review_creation_date,
--         cor.product_id,
--         cor.seller_id,
--         cor.order_status,
--         cor.order_delivered_customer_date,

--         p.product_custome_key,
--         p.product_category,
--         p.category_english_name
--     FROM combine_order_review cor
--     LEFT JOIN gold_BE.dim_products p   
--         ON cor.product_id = p.product_id
-- ),

-- connect_seller AS (
--     SELECT 
--         cp.review_id,
--         cp.order_id,
--         cp.review_score,
        
      

--         cp.product_id,
--         cp.product_custome_key,
--         cp.product_category,
--         cp.category_english_name,

--         cp.seller_id,
--         s.seller_custome_key,
--         s.seller_city,
--         s.seller_state,
--         s.seller_zip_code,
--         cp.order_status,

--         CASE 
--             WHEN cp.review_creation_date < cp.order_delivered_customer_date 
--                 THEN cp.order_delivered_customer_date
--             ELSE cp.review_creation_date
--         END 'review_creation_date',

--         CASE 
--             WHEN cp.review_creation_date < cp.order_delivered_customer_date 
--                 THEN cp.review_creation_date
--             ELSE cp.order_delivered_customer_date
--         END 'order_delivered_customer_date'

--     FROM connect_product cp  
--     LEFT JOIN gold_BE.dim_sellers s   
--         ON cp.seller_id = s.seller_id
-- )

-- SELECT 
--     *
-- FROM connect_seller
-- WHERE product_custome_key IS NOT NULL 

-- SELECT DISTINCT product_category FROM gold_BE.dim_products

-- SELECT 
-- --     -- oi.order_id oi_o_id,
-- --     -- COALESCE(oi.order_id,rv.order_id) as REMOVE_NULL_OI_T,
-- --     -- rv.order_id rv_o_id,
-- --     -- COALESCE(rv.order_id,oi.order_id) as REMOVE_NULL_RV_T,
-- --     -- od.order_id od_o_id,
-- --     -- COALESCE(od.order_id,rv.order_id) as REMOVE_NULL_OD_T,
-- --     rv.review_score,
-- --     rv.review_creation_date,
-- --     od.order_delivered_customer_date
-- -- FROM silver_BE.olist_order_reviews_dataset rv
-- -- LEFT JOIN silver_BE.olist_order_items_dataset oi  
-- -- ON rv.order_id = oi.order_id
-- -- LEFT JOIN silver_BE.olist_orders_dataset od  
-- -- ON rv.order_id = od.order_id
-- -- WHERE od.order_delivered_customer_date > rv.review_creation_date



-- SELECT 
--     oi.order_id oi_o_id,
--     rv.order_id rv_o_id,
--     COALESCE(oi.order_id,rv.order_id) as REMOVE_NULL_O_T,
--     COALESCE(rv.order_id,oi.order_id) as REMOVE_NULL_R_T,
--     rv.review_score
-- FROM silver_BE.olist_order_reviews_dataset rv
-- LEFT JOIN silver_BE.olist_orders_dataset oi  
-- ON rv.order_id = oi.order_id
-- WHERE rv.order_id IS NULL

-- -- SELECT DISTINCT order_id, COUNT(*) FROM silver_BE.olist_orders_dataset GROUP BY order_id
-- -- SELECT DISTINCT order_id, COUNT(*) FROM silver_BE.olist_order_items_dataset GROUP BY order_id



-- -- SELECT 
-- --     op.order_id oi_o_id,
-- --     -- COALESCE(oi.order_id,rv.order_id) as REMOVE_NULL_OI_T,
-- --     -- rv.order_id rv_o_id,
-- --     -- COALESCE(rv.order_id,oi.order_id) as REMOVE_NULL_RV_T,
-- --     -- od.order_id od_o_id,
-- --     -- COALESCE(od.order_id,rv.order_id) as REMOVE_NULL_OD_T,
-- --     op.product_category,
-- --     rv.review_score

-- -- FROM silver_BE.olist_order_reviews_dataset rv
-- -- LEFT JOIN ( 
-- --     SELECT  oit.order_id, pt.product_id,pt.product_category FROM silver_BE.olist_order_items_dataset oit 
-- --     LEFT JOIN gold_BE.dim_products pt  
-- --     ON pt.product_id = oit.product_id
-- --      ) as op 
-- -- ON rv.order_id = op.order_id

-- -- With  


-- WITH combine_order_review AS (
--     SELECT 
--     --oi.order_id as order_item_oid,
--     COALESCE(oi.order_id,rv.order_id) as order_item_oid,
--     --rv.order_id review_oid,
--     COALESCE(rv.order_id,oi.order_id) as review_oid,
--     --od.order_id order_oid,
--     COALESCE(od.order_id,rv.order_id) as order_oid,
--     rv.review_score,
--     oi.product_id ,
--     oi.seller_id as oi_seller,
--     rv.review_creation_date,
--     od.order_delivered_customer_date
-- FROM silver_BE.olist_order_reviews_dataset rv
-- LEFT JOIN silver_BE.olist_order_items_dataset oi  
-- ON rv.order_id = oi.order_id
-- LEFT JOIN silver_BE.olist_orders_dataset od  
-- ON rv.order_id = od.order_id
-- ), connect_product AS (

--     SELECT cor.*, p.product_category,p.category_english_name FROM combine_order_review cor
--     LEFT JOIN gold_BE.dim_products p   
--     ON cor.product_id = p.product_id
-- ),connect_seller AS (
--     SELECT cp.*,s.seller_id, s.seller_city FROM connect_product cp  
--     LEFT JOIN gold_BE.dim_sellers s   
--     ON cp.oi_seller = s.seller_id
-- ) SELECT * from connect_seller
-- GO