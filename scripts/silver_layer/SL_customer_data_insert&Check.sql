
TRUNCATE TABLE silver_BE.olist_customers_dataset 

PRINT 'INSERT CUSTOMER DATA TO SILVER LAYER'
-- Insert cleaned and deduplicated customer data into silver layer table
INSERT INTO silver_BE.olist_customers_dataset (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT 

    -- Trim whitespace from all fields to ensure data cleanliness
    TRIM(customer_id) as customer_id,
    TRIM(customer_unique_id) as customer_unique_id,
    RIGHT(REPLICATE(0, 5) + CAST(TRIM(customer_zip_code_prefix) AS VARCHAR(5)), 5) AS customer_zip_code_prefix,
    TRIM(customer_city) as customer_city,
    TRIM(customer_state) as customer_state
FROM (

    -- Deduplicate records based on customer_unique_id
    -- Using ROW_NUMBER to keep only the first occurrence per customer_unique_id
    SELECT *,
    ROW_NUMBER() OVER(PARTITION BY customer_id, customer_unique_id ORDER BY customer_state) as flag
    FROM bronze_BE.olist_customers_dataset

     -- Optional: Filter out records with critical missing data
    WHERE customer_id IS NOT NULL 
    AND customer_id != ''
    AND customer_unique_id IS NOT NULL 
    AND customer_unique_id != ''

 -- Filter to keep only the first record for each customer_unique_id
)t WHERE flag = 1


----- DATA QUALITY CHECK: Verify no duplicate customer_unique_id remain
----- EXPECTED RESULT: ZERO ROWS

SELECT * FROM (
    SELECT *,
    ROW_NUMBER() OVER(PARTITION BY customer_id, customer_unique_id ORDER BY customer_state) as flag
    FROM silver_BE.olist_customers_dataset
)t WHERE flag > 1


----- DATA QUALITY CHECK: Verify all whitespace has been properly trimmed
----- EXPECTED RESULT: ZERO ROWS
SELECT 
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM silver_BE.olist_customers_dataset
WHERE customer_id != TRIM(customer_id) 
    OR customer_unique_id != TRIM(customer_unique_id)
    OR customer_zip_code_prefix != TRIM(customer_zip_code_prefix)
    OR customer_city != TRIM(customer_city)
    OR customer_state != TRIM(customer_state)

----- DATA QUALITY CHECK: CHECK FOR NULL/EMPTY VALUES IN CRITICAL FIELDS
----- EXPECTED RESULT: ZERO ROWS
SELECT * 
FROM  silver_BE.olist_customers_dataset
WHERE customer_city IS NULL 
    OR customer_state IS NULL 
    OR customer_id IS NULL 
    OR customer_unique_id IS NULL 
    OR customer_zip_code_prefix IS NULL 

SELECT * 
FROM  silver_BE.olist_customers_dataset
WHERE customer_city ='' 
    OR customer_state ='' 
    OR customer_zip_code_prefix='' 

SELECT * FROM silver_BE.olist_customers_dataset
WHERE LEN(customer_zip_code_prefix) < 5