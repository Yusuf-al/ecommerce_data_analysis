-- Preview existing silver table
SELECT * 
FROM silver_BE.olist_sellers_dataset;
GO

-- Clear silver table before loading new cleaned data
TRUNCATE TABLE silver_BE.olist_sellers_dataset;
GO


/* ============================================================================
 STEP 1: DEDUPLICATION + BASIC STANDARDIZATION
 - Remove null seller_id
 - Standardize ZIP to 5 digits
 - Trim city/state and uppercase state
 - Use ROW_NUMBER to pick the best record per seller_id
============================================================================ */
WITH deduplicated_seller_data AS (
    SELECT 
        seller_id,
        RIGHT(REPLICATE(0, 5) + CAST(seller_zip_code_prefix AS VARCHAR(5)), 5) AS seller_zip_code_prefix,
        TRIM(seller_city) AS seller_city,
        UPPER(TRIM(seller_state)) AS seller_state,
        ROW_NUMBER() OVER (
            PARTITION BY seller_id
            ORDER BY seller_zip_code_prefix  -- choose preferred ZIP
        ) AS flag
    FROM bronze_BE.olist_sellers_dataset
    WHERE seller_id IS NOT NULL
),

/* ============================================================================
 STEP 2: ZIP CODE VALIDATION
 - Keep only rows where ZIP length >= 5 (proper Brazilian format)
============================================================================ */
check_zip_code AS (
    SELECT *
    FROM deduplicated_seller_data
    WHERE LEN(seller_zip_code_prefix) >= 5
),

/* ============================================================================
 STEP 3: CITY + STATE VALIDATION
 - Ensure both city and state exist (no nulls)
============================================================================ */
check_city_state AS (
    SELECT *
    FROM check_zip_code
    WHERE seller_city IS NOT NULL 
      AND seller_state IS NOT NULL
),

/* ============================================================================
 STEP 4: CITY NAME CLEANING
 - Replace special chars
 - Remove text after ',' '-' '@'
 - If city contains numbers, replace it with state (fallback correction)
============================================================================ */
cleaned_city AS (
    SELECT 
        seller_id,
        seller_zip_code_prefix,
        LTRIM(RTRIM(
            CASE 
                WHEN CHARINDEX('-', city_part) > 0 THEN LEFT(city_part, CHARINDEX('-', city_part)-1)
                WHEN CHARINDEX('@', city_part) > 0 THEN LEFT(city_part, CHARINDEX('@', city_part)-1)
                WHEN city_part LIKE  '%[0-9]%' THEN seller_state
                ELSE city_part
            END
        )) AS seller_city,
        seller_state,
        flag
    FROM (
        SELECT *,
               LEFT(REPLACE(REPLACE(seller_city,'/','-'),'\','-'), 
                    CHARINDEX(',', REPLACE(REPLACE(seller_city,'/','-'),'\','-')+',') - 1
               ) AS city_part
        FROM check_city_state
    ) t
) 

/* ============================================================================
 INSERT CLEANED DATA INTO THE SILVER TABLE
 - Keep only flag = 1 → the best cleaned record per seller
============================================================================ */
INSERT INTO silver_BE.olist_sellers_dataset (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state 
)
SELECT 
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state 
FROM cleaned_city
WHERE flag = 1;



/* ============================================================================
 QUALITY CHECKS (RECRUITERS LOVE THESE)
============================================================================ */

-- Check duplicate ZIP/CITY/STATE combinations
SELECT 
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    COUNT(*) 
FROM silver_BE.olist_sellers_dataset
GROUP BY seller_zip_code_prefix, seller_city, seller_state
HAVING COUNT(*) > 1;


-- Check duplicate seller_id (should be exactly 1)
SELECT seller_id, COUNT(*)
FROM silver_BE.olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- Check for NULLs
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_id IS NULL;
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_city IS NULL OR seller_state IS NULL;
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_zip_code_prefix IS NULL;


-- Check for invalid ZIPs
SELECT * 
FROM silver_BE.olist_sellers_dataset
WHERE CAST(seller_zip_code_prefix AS INT) < 0;


-- Check whitespace or formatting issues
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_city != TRIM(seller_city);
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_state != TRIM(seller_state);
SELECT * FROM silver_BE.olist_sellers_dataset WHERE seller_state != UPPER(seller_state);
SELECT * FROM silver_BE.olist_sellers_dataset WHERE LEN(seller_zip_code_prefix) < 5;


-- Check cities containing numbers (likely invalid)
SELECT *
FROM silver_BE.olist_sellers_dataset
WHERE seller_city LIKE '%[0-9]%';

-- Check cities containing special character like [-,/,\,@]
-- expected outcome is zero
SELECT 
    seller_city
FROM silver_BE.olist_sellers_dataset WHERE seller_city  LIKE '%-%' 

SELECT 
    seller_city
FROM silver_BE.olist_sellers_dataset WHERE seller_city  LIKE '%,%' 

SELECT 
    seller_city
FROM silver_BE.olist_sellers_dataset WHERE seller_city  LIKE '%@%' 


/* 
------------------------------------
------ALTERNATIVE CAN BE USED ------
------------------------------------
(
    SELECT 
        seller_id,
        seller_zip_code_prefix,

        -- Final cleaned city transformation
        LTRIM(RTRIM(
            CASE 
                WHEN CHARINDEX('-', LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1)) > 0
                    THEN LEFT(
                        LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1),
                        CHARINDEX('-', LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1)) - 1
                    )
                WHEN CHARINDEX('@', LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1)) > 0
                    THEN LEFT(
                        LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1),
                        CHARINDEX('@', LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1)) - 1
                    )
                WHEN cleaned_city LIKE '%[0-9]%' 
                    THEN seller_state  -- city invalid → fall back to state
                ELSE LEFT(cleaned_city, CHARINDEX(',', cleaned_city + ',') - 1)
            END
        )) AS seller_city,

        seller_state,
        flag
    FROM (
        -- preprocess city for easier cleansing
        SELECT 
            seller_id,
            seller_zip_code_prefix,
            REPLACE(REPLACE(seller_city, '/', '-'), '\', '-') AS cleaned_city,
            seller_state,
            flag
        FROM check_city_state
    ) AS t
)
*/
