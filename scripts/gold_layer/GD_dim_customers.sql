------------------------------------------------------------
-- Drop the customer dimension view if it already exists
-- This ensures the script can be re-run without errors
------------------------------------------------------------
IF OBJECT_ID('gold_BE.dim_customers','V') IS NOT NULL
    DROP VIEW gold_BE.dim_customers;
GO


------------------------------------------------------------
-- Create Customer Dimension View
-- Purpose:
--  - Generate a surrogate customer key
--  - Standardize and expose clean customer address data
-- Expected Output:
--  - One row per customer with ID, city, state and ZIP
------------------------------------------------------------
CREATE VIEW gold_BE.dim_customers AS
SELECT 
    -- Surrogate primary key for data warehousing
    ROW_NUMBER() OVER(ORDER BY customer_state) AS customer_custome_key,

    -- Original OLTP customer identifier
    customer_id,

    -- Standardized ZIP column naming for readability
    customer_zip_code_prefix AS customer_zip_code,

    -- Location details
    customer_city,
    customer_state

FROM silver_BE.olist_customers_dataset;
GO


------------------------------------------------------------
-- Validating the data quality
-- Query: Check for customers without a valid city
-- Expected Outcome:
--  - Rows shown here indicate missing geo information
------------------------------------------------------------
SELECT * 
FROM gold_BE.dim_customers
WHERE customer_city IS NULL;
