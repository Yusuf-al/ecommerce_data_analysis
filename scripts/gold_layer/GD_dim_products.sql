
------------------------------------------------------------
-- Drop the Product Dimension view if it already exists
-- This ensures re-execution without conflict
------------------------------------------------------------
IF OBJECT_ID('gold_BE.dim_products','V') IS NOT NULL
    DROP VIEW gold_BE.dim_products;
GO


------------------------------------------------------------
-- Create Product Dimension View
-- Purpose:
--  - Consolidate product metadata and price info
--  - Remove duplicates
--  - Enrich product category with English meaning
--  - Assign surrogate keys for DW consumption
-- Expected Output:
--  - One cleaned record per product with full attributes,
--    including category, price, physical measurements.
------------------------------------------------------------
CREATE VIEW gold_BE.dim_products AS

------------------------------------------------------------
-- STEP 1: Combine product info from the order items dataset
--         and the master products dataset.
--         FULL JOIN ensures no product is lost if
--         it appears only in one dataset.
------------------------------------------------------------
WITH combine_data AS (
    SELECT 
        -- Prefer whichever product_id is available
        COALESCE(op.product_id, p.product_id) AS product_id,

        /* Category fallback */
        CASE 
            WHEN p.product_category_name IS NULL THEN 'unknown'
            ELSE p.product_category_name
        END AS product_category,

        -- Price from order-item data
        op.price,

        /* Product physical attributes */
        p.product_photos_qty AS photos_quantity,
        p.product_height_cm AS product_height,
        p.product_length_cm AS product_length,
        p.product_width_cm  AS product_width,
        p.product_weight_g  AS product_weight

    FROM silver_BE.olist_order_items_dataset op
    FULL JOIN silver_BE.olist_products_dataset p  
        ON op.product_id = p.product_id
),

------------------------------------------------------------
-- STEP 2: Deduplicate product records
-- Priority rules:
--  - Prefer rows with known category
--  - Prefer rows with photo information available
------------------------------------------------------------
deduplicated_data AS (
    SELECT 
        product_id,
        product_category,
        price,
        photos_quantity,
        product_height,
        product_length,
        product_width,
        product_weight,

        ROW_NUMBER() OVER (
            PARTITION BY product_id 
            ORDER BY 
                CASE WHEN product_category = 'unknown' THEN 1 ELSE 0 END,
                CASE WHEN photos_quantity IS NULL THEN 1 ELSE 0 END
        ) AS flag
    FROM combine_data
),

------------------------------------------------------------
-- STEP 3: Add English translation for the category
-- from the translation lookup dataset
------------------------------------------------------------
add_category_eng_name AS (
    SELECT  
        d.product_id,
        COALESCE(d.product_category, t.product_category_name) AS product_category,
        COALESCE(t.product_category_name_english, d.product_category) AS category_english_name,
        d.price,
        d.photos_quantity,
        d.product_height,
        d.product_length,
        d.product_width,
        d.product_weight,
        d.flag
    FROM deduplicated_data d
    LEFT JOIN silver_BE.product_category_name_translation t
        ON t.product_category_name = d.product_category
)

------------------------------------------------------------
-- Final Output with surrogate product key
------------------------------------------------------------
SELECT 
    ROW_NUMBER() OVER(ORDER BY product_id) AS product_custome_key,
    product_id,
    product_category,
    category_english_name,
    price,
    photos_quantity,
    product_height,
    product_length,
    product_width,
    product_weight
FROM add_category_eng_name
WHERE flag = 1;
GO


SELECT * FROM gold_BE.dim_products





-- SELECT * FROM gold_BE.dim_products
-- GO



-- SELECT 
--     ROW_NUMBER() OVER(ORDER BY product_id) as product_custome_key,
--     product_id,
--     CASE 
--         WHEN pe.product_category_name IS NULL THEN p.product_category_name
--         ELSE pe.product_category_name
--     END as product_category,
--     CASE 
--         WHEN pe.product_category_name_english IS NULL THEN p.product_category_name
--         ELSE pe.product_category_name_english
--     END 'category_english_name',
   
--     product_photos_qty as photos_quantity,
--     product_height_cm as product_height,
--     product_length_cm as product_length,
--     product_width_cm as product_width,
--     product_weight_g as product_weight
-- FROM silver_BE.olist_products_dataset p  
-- LEFT JOIN silver_BE.product_category_name_translation pe  
-- ON TRIM(UPPER(p.product_category_name)) =TRIM(UPPER(pe.product_category_name)) 
-- GO