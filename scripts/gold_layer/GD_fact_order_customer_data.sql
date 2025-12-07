



-- -- SELECT 
-- --     o.order_id as order_id,
-- --     o.customer_id as customer_id,
-- --     i.product_id as product_id,
-- --     o.order_purchase_timestamp as purchase_date,
-- --     o.order_delivered_customer_date as delivered_date,
-- --     DATEDIFF(DAY,o.order_purchase_timestamp,o.order_delivered_customer_date) as order_duration,
-- --     i.price as product_price,
-- --     i.order_item_id as order_quantity,
-- --     i.price * i.order_item_id as total_cost,
-- --     i.freight_value as shipping_cost,
-- --     YEAR(o.order_purchase_timestamp) as order_year,
-- --     MONTH(o.order_purchase_timestamp) as order_month
-- -- FROM silver_BE.olist_orders_dataset o
-- -- LEFT JOIN  silver_BE.olist_order_items_dataset i
-- -- ON i.order_id = o.order_id
-- -- WHERE o.order_delivered_customer_date IS NOT NULL
-- -- ORDER BY YEAR(o.order_purchase_timestamp) DESC



-- -- SELECT * FROM silver_BE.olist_order_items_dataset


-- -- SELECT * FROM silver_BE.olist_customers_dataset c  
-- -- LEFT JOIN silver_BE.olist_geolocation_dataset g  
-- -- ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
-- -- WHERE g.geolocation_zip_code_prefix IS NOT NULL
-- -- ORDER BY customer_zip_code_prefix, geolocation_zip_code_prefix
-- -- GO

-- -- IF OBJECT_ID('gold_BE.dim_geo_location','V') IS NOT NULL
-- --         DROP VIEW gold_BE.dim_geo_location;
-- --     GO


-- -- SELECT * FROM (

-- -- SELECT *,
-- -- ROW_NUMBER() OVER(PARTITION BY geolocation_city,geolocation_state,location_zip_code
-- --                     ORDER BY location_zip_code) as flag
-- -- FROM (

-- -- SELECT 
   
-- --     /* Final standardized city */
-- --     COALESCE(
-- --         g.geolocation_city,
-- --         c.customer_city
-- --     ) AS geolocation_city,

-- --     /* Final standardized state */
-- --     COALESCE(
-- --         g.geolocation_state,
-- --         c.customer_state
-- --     ) AS geolocation_state,

-- --     /* Final merged ZIP code */
-- --     CASE 
-- --         WHEN c.customer_city = g.geolocation_city
-- --          AND c.customer_state = g.geolocation_state
-- --          AND c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
-- --             THEN c.customer_zip_code_prefix

-- --         WHEN g.geolocation_zip_code_prefix IS NULL
-- --             THEN c.customer_zip_code_prefix

-- --         WHEN c.customer_zip_code_prefix IS NULL
-- --             THEN g.geolocation_zip_code_prefix

-- --         ELSE g.geolocation_zip_code_prefix
-- --     END AS location_zip_code
-- -- FROM silver_BE.olist_customers_dataset c
-- -- LEFT JOIN silver_BE.olist_geolocation_dataset g
-- --     ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
-- -- )t 
-- -- )t WHERE flag = 1
-- -- GO

-- -- SELECT * FROM (

-- -- SELECT *,
-- --     ROW_NUMBER() OVER(PARTITION BY New_proID ORDER BY New_proID) as flag
-- --  FROM (


-- WITH combine_data AS (
-- SELECT 
--     op.product_id as od_pro_id,
--     p.product_id as p_pro_id,
--     p.product_category_name,
--     op.price,
--     op.freight_value,
--     CASE WHEN p.product_id IS NULL THEN op.product_id
--          WHEN op.product_id IS NULL THEN p.product_id
--          WHEN p.product_id = op.product_id THEN op.product_id
--          ELSE op.product_id
--     END 'New_proID',
--     CASE WHEN p.product_category_name IS NULL THEN 'unknown'
--         ELSE p.product_category_name
--     END 'product_cat',
--     p.product_photos_qty as photos_quantity,
--     p.product_height_cm as product_height,
--     p.product_length_cm as product_length,
--     p.product_width_cm as product_width,
--     p.product_weight_g as product_weight
--  FROM silver_BE.olist_order_items_dataset op
-- FULL JOIN silver_BE.olist_products_dataset p  
-- ON op.product_id = p.product_id
-- ), deduplicated_date AS (
--     SELECT 
--     New_proID as product_id,
--     product_cat as product_category,
--     price,
--     freight_value as shippig_cost,
--     photos_quantity,
--     product_height,
--     product_length,
--     product_width,
--     product_weight,
--     ROW_NUMBER() OVER(PARTITION BY New_proID ORDER BY New_proID) as flag
--     FROM combine_data
-- ),add_cattegory_eng_name AS (

--     SELECT  
--     pn.product_id,
--     CASE 
--         WHEN  pn.product_category IS NULL THEN pe.product_category_name
--         WHEN  pe.product_category_name IS NULL THEN pn.product_category
--         ELSE pn.product_category
--     END 'product_category',

--     CASE 
--         WHEN pe.product_category_name_english IS NULL THEN pn.product_category
--         ELSE pe.product_category_name_english
--     END 'category_english_name',
--     pn.price,
--     pn.shippig_cost,
--     pn.photos_quantity,
--     pn.product_height,
--     pn.product_length,
--     pn.product_width,
--     pn.product_weight,
--     pn.flag
--     FROM deduplicated_date pn
--     LEFT JOIN silver_BE.product_category_name_translation pe
--     ON pe.product_category_name = pn.product_category
-- )

-- SELECT 
--     product_id,
--     product_category,
--     category_english_name,
--     price,
--     shippig_cost,
--     photos_quantity,
--     product_height,
--     product_length,
--     product_width,
--     product_weight
-- FROM add_cattegory_eng_name
-- WHERE flag = 1
-- GO


