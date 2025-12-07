/*======================================================================
    STEP 1: Clear Silver Layer Table
    - Ensures fresh load with cleaned & deduplicated records
======================================================================*/
TRUNCATE TABLE silver_BE.olist_order_payments_dataset

/*======================================================================
    STEP 2: Insert Cleaned, Normalized & Deduplicated Payment Records
======================================================================*/
INSERT INTO silver_BE.olist_order_payments_dataset (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value 
)

SELECT
    order_id,
    payment_sequential,

    -- Payment type normalization:
    -- If payment_value = 0 → should be "voucher"
    CASE 
        WHEN payment_value = 0 THEN 'voucher'
        ELSE TRIM(payment_type)
    END AS payment_type,

    -- Installment cleaning rule:
    -- (1) If installments = 0 → set to 1
    -- (2) If payment_value is too small (0–1 range) → enforce 1 installment
    CASE
        WHEN payment_installments = 0 THEN 1 
        WHEN ROUND(CAST(payment_value as DECIMAL(10,2)),2) BETWEEN 0 AND 1 THEN 1
        ELSE payment_installments
    END payment_installments,

    -- Normalize payment values
    ROUND(CAST(payment_value as DECIMAL(10,2)),2) as payment_value
FROM (

     /*-----------------------------------------------------------
            Deduplication Logic:
            - Partition by business keys
            - Keep first record only
        -----------------------------------------------------------*/
    SELECT *,
        
        ROW_NUMBER() over( PARTITION BY order_id,
                                    payment_installments,
                                    payment_type,
                                    payment_value
                    ORDER BY     order_id) as flag
    FROM bronze_BE.olist_order_payments_dataset
     WHERE payment_value >= 0 
        AND payment_type != 'not_defined'
        AND payment_type is NOT NULL 
        AND TRIM(payment_type)  != ''

)t WHERE flag = 1

/*======================================================================
    STEP 3: DATA QUALITY CHECKS (All should return **0 rows expected**)
======================================================================*/

/*-----------------------------------------------------------
    Check 1: Empty payment_type
    EXPECTED: 0 rows
-----------------------------------------------------------*/
SELECT * FROM silver_BE.olist_order_payments_dataset
WHERE TRIM(payment_type)  = ''


/*-----------------------------------------------------------
    Check 2: Invalid installment count
    - Must never be NULL or 0 after cleaning
    EXPECTED: 0 rows
-----------------------------------------------------------*/
SELECT * FROM silver_BE.olist_order_payments_dataset
WHERE payment_installments is NULL OR payment_installments = 0


/*-----------------------------------------------------------
    Check 3: Should not contain undefined payments
    EXPECTED: 0 rows
-----------------------------------------------------------*/
SELECT * FROM silver_BE.olist_order_payments_dataset
WHERE payment_type = 'not_defined' AND payment_value = 0

/*-----------------------------------------------------------
    Check 4: Negative payment value check
    EXPECTED: 0 rows
-----------------------------------------------------------*/
SELECT 
    MIN(CAST(payment_value as decimal(10,2))) as minimum_payment,
    MAX(CAST(payment_value as decimal(10,2))) as maximum_payment
FROM silver_BE.olist_order_payments_dataset
WHERE payment_value < 0




/*-----------------------------------------------------------
    Check 5: Duplicate check inside Silver
    - Ensures deduplication success
    EXPECTED: 0 rows
-----------------------------------------------------------*/

SELECT * FROM (

 SELECT *,
        ROW_NUMBER() over( PARTITION BY order_id,
                                    payment_installments,
                                    payment_type,
                                    payment_value
                    ORDER BY     order_id) as flag
FROM silver_BE.olist_order_payments_dataset
)t WHERE flag > 1


/*-----------------------------------------------------------
    Check 6: View all distinct payment methods
-----------------------------------------------------------*/

SELECT DISTINCT payment_type FROM silver_BE.olist_order_payments_dataset


/*-----------------------------------------------------------
    Check 7: Validation for installment rule
    - If payment_value between 0 and 1 → installment must be 1
    EXPECTED: 0 rows
-----------------------------------------------------------*/
SELECT * FROM silver_BE.olist_order_payments_dataset
WHERE  payment_value BETWEEN 0 AND 1 AND payment_installments != 1