
-- View current Silver table
SELECT * 
FROM silver_BE.olist_products_dataset;
GO

-- Reset Silver table before loading cleaned data
TRUNCATE TABLE silver_BE.olist_products_dataset;
GO


/**********************************************************************************************
 STEP 1: DEDUPLICATION  
 - Remove duplicate product entries based on product_id
 - Keep the first record ordered by product_category_name
 - Ignore records where product_category_name is NULL
***********************************************************************************************/
WITH deduplicated_product_data AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_id
            ORDER BY product_category_name
        ) AS flag
    FROM bronze_BE.olist_products_dataset
    WHERE product_category_name IS NOT NULL
),

/**********************************************************************************************
 STEP 2: DATA CLEANING & STANDARDIZATION
 - Trim category names
 - Convert negative product_photos_qty to absolute value
 - Convert null values in weight/dimensions to Zero
 - Only keep rows where all dimensions are NOT NULL 
***********************************************************************************************/
check_physical_dimensions AS (
    SELECT 
        product_id,
        TRIM(product_category_name) AS product_category_name,
        NULLIF(product_name_lenght, 0) AS product_name_lenght,
        NULLIF(product_description_lenght, 0) AS product_description_lenght,

        CASE 
            WHEN product_photos_qty < 0 THEN ABS(product_photos_qty)
            ELSE product_photos_qty
        END AS product_photos_qty,

        NULLIF(product_weight_g, 0) AS product_weight_g,
        NULLIF(product_length_cm, 0) AS product_length_cm,
        NULLIF(product_height_cm, 0) AS product_height_cm,
        NULLIF(product_width_cm, 0) AS product_width_cm,

        flag
    FROM deduplicated_product_data

    -- YOUR FILTER: only keep rows where ALL dimensions exist (not NULL)
    WHERE product_length_cm IS NOT NULL 
      AND product_height_cm IS NOT NULL 
      AND product_width_cm IS NOT NULL
)

-- Load cleaned data into the SILVER layer
INSERT INTO silver_BE.olist_products_dataset (
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT 
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM check_physical_dimensions
WHERE flag = 1;     -- Keep only the deduplicated rows



/**********************************************************************************************
----------------------- QUALITY CHECK QUERIES-----------------------
--------------------------------------------------------------------  
 These are basic validation queries after the Silver load, ensuring:
 - No negative values
 - No invalid lengths/descriptions
 - No untrimmed category names
***********************************************************************************************/

-- Check for negative photos (should be zero due to cleaning)
SELECT *
FROM silver_BE.olist_products_dataset
WHERE product_photos_qty < 0;


-- Check for invalid / zero product name length
SELECT *
FROM silver_BE.olist_products_dataset
WHERE product_name_lenght <= 0;


-- Check for invalid / zero product description length
SELECT *
FROM silver_BE.olist_products_dataset
WHERE product_description_lenght <= 0;


-- Check for invalid (negative) dimensions
SELECT *
FROM silver_BE.olist_products_dataset
WHERE product_length_cm < 0 
   OR product_height_cm < 0 
   OR product_width_cm < 0;


-- Check category names where trimming did not match original
SELECT *
FROM silver_BE.olist_products_dataset
WHERE product_category_name != TRIM(product_category_name);

-- Check category names for null values
SELECT * FROM silver_BE.olist_products_dataset 
WHERE product_category_name is NULL

-- -- Check for invalid description lenght
SELECT * FROM silver_BE.olist_products_dataset 
WHERE product_description_lenght is NULL OR product_description_lenght <=0

-- -- Check for invalid name lenght
SELECT * FROM silver_BE.olist_products_dataset 
WHERE product_name_lenght is NULL OR product_name_lenght <=0



SELECT * FROM gold_BE.dim_products