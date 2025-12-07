-- ============================================
-- STEP 0: View current data in Silver Layer
-- ============================================
SELECT * 
FROM silver_BE.olist_order_reviews_dataset;
GO

-- ============================================
-- STEP 1: Clear Silver Layer Table
-- ============================================
TRUNCATE TABLE silver_BE.olist_order_reviews_dataset;
GO

-- ============================================
-- STEP 2: Insert cleaned & deduplicated review data
-- ============================================
WITH raw_data AS (
    -- Assign row numbers per review to handle duplicates
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY review_id,
                            review_score,
                            review_creation_date,
                            review_answer_timestamp
               ORDER BY review_creation_date
           ) AS flag
    FROM bronze_BE.olist_order_reviews_dataset
),
check_null_ids AS (
    -- Remove rows with null critical IDs
    SELECT *
    FROM raw_data
    WHERE order_id IS NOT NULL
      AND review_id IS NOT NULL
),
check_reviews AS (
    -- Keep only valid review scores between 1 and 5
    SELECT *
    FROM check_null_ids
    WHERE review_score IS NOT NULL
      AND review_score BETWEEN 1 AND 5
),
check_reviews_dates AS (
    -- Ensure creation date <= answer timestamp and both are not null
    SELECT *
    FROM check_reviews
    WHERE review_creation_date IS NOT NULL
      AND review_answer_timestamp IS NOT NULL
      AND review_creation_date <= review_answer_timestamp
)

-- Insert cleaned records into Silver Layer
INSERT INTO silver_BE.olist_order_reviews_dataset (
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
)
SELECT 
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM check_reviews_dates
WHERE flag = 1;  -- Keep only the first record per duplicate set
GO

-- ============================================
-- STEP 3: DATA QUALITY CHECKS
-- ============================================

-- 1. Check for duplicates (expected: 0 rows)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY review_id,
                            review_score,
                            review_creation_date,
                            review_answer_timestamp
               ORDER BY review_creation_date
           ) AS flag
    FROM silver_BE.olist_order_reviews_dataset
) t
WHERE flag > 1;

-- 2. Check for review scores outside valid range (1–5) (expected: 0 rows)
SELECT *
FROM silver_BE.olist_order_reviews_dataset
WHERE review_score < 1 OR review_score > 5;

-- 3. Count review_id duplicates (expected: max 1 per review_id)
SELECT review_id, COUNT(*) 
FROM silver_BE.olist_order_reviews_dataset
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 4. Check for invalid date sequences (creation > answer) (expected: 0 rows)
SELECT *
FROM silver_BE.olist_order_reviews_dataset
WHERE review_creation_date > review_answer_timestamp;

-- 5. Check for NULL review IDs (expected: 0 rows)
SELECT review_id 
FROM silver_BE.olist_order_reviews_dataset
WHERE review_id IS NULL;

-- 6. Check for NULL order IDs (expected: 0 rows)
SELECT order_id 
FROM silver_BE.olist_order_reviews_dataset
WHERE order_id IS NULL;

-- 7. Check for NULL creation dates (expected: 0 rows)
SELECT review_creation_date 
FROM silver_BE.olist_order_reviews_dataset
WHERE review_creation_date IS NULL;

-- 8. Check for NULL answer timestamps (expected: 0 rows)
SELECT review_answer_timestamp 
FROM silver_BE.olist_order_reviews_dataset
WHERE review_answer_timestamp IS NULL;