------------------------------------------------------------------------------
-- VIEW EXISTING SILVER TABLE (FOR VALIDATION)
------------------------------------------------------------------------------
SELECT * 
FROM silver_BE.product_category_name_translation;


------------------------------------------------------------------------------
-- CLEAR SILVER TABLE BEFORE LOADING CLEAN DATA
------------------------------------------------------------------------------
TRUNCATE TABLE silver_BE.product_category_name_translation;


------------------------------------------------------------------------------
-- INSERT CLEANED & DEDUPLICATED DATA INTO SILVER TABLE
-- Steps:
-- 1. Use ROW_NUMBER to deduplicate (keep only the first unique pair)
-- 2. Standardize by TRIM() on both category name fields
------------------------------------------------------------------------------

INSERT INTO silver_BE.product_category_name_translation (
    product_category_name,
    product_category_name_english
)
SELECT 
    TRIM(product_category_name) AS product_category_name,
    TRIM(product_category_name_english) AS product_category_name_english
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY product_category_name, product_category_name_english
            ORDER BY product_category_name
        ) AS flag
    FROM bronze_BE.product_category_name_translation
) t
WHERE flag = 1;


------------------------------------------------------------------------------
-- QUALITY CHECKS (FOR CLEANING VALIDATION)
------------------------------------------------------------------------------

-- Check if duplicates still exist after trimming
SELECT 
    TRIM(product_category_name_english) AS product_category_name_english,
    TRIM(product_category_name) AS product_category_name,
    COUNT(*) 
FROM silver_BE.product_category_name_translation
GROUP BY 
    TRIM(product_category_name_english), 
    TRIM(product_category_name)
HAVING COUNT(*) > 1;


-- Check for leading/trailing spaces (should return 0 rows)
SELECT *
FROM silver_BE.product_category_name_translation
WHERE TRIM(product_category_name_english) != product_category_name_english;


SELECT *
FROM silver_BE.product_category_name_translation
WHERE TRIM(product_category_name) != product_category_name;


-- Check for NULL or blank category names
SELECT *
FROM silver_BE.product_category_name_translation
WHERE product_category_name IS NULL 
   OR product_category_name = ' ';


SELECT *
FROM silver_BE.product_category_name_translation
WHERE product_category_name_english IS NULL 
   OR product_category_name_english = ' ';
