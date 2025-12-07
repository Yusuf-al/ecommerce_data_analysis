TRUNCATE TABLE silver_BE.olist_orders_dataset;
GO


/* ============================================================
   STEP 1: Remove duplicates based on order_id
   - Keep only the earliest purchase timestamp per order
   ============================================================ */
WITH raw_Data_with_deduplication AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY order_id 
               ORDER BY order_purchase_timestamp ASC
           ) AS flag
    FROM bronze_BE.olist_orders_dataset
    WHERE order_id IS NOT NULL
),


/* ============================================================
   STEP 2: Remove rows missing required essential fields
   ============================================================ */
check_null AS (
    SELECT *
    FROM raw_Data_with_deduplication
    WHERE customer_id IS NOT NULL
      AND order_status IS NOT NULL
),


/* ============================================================
   STEP 3: Validate timestamps according to business rules
   - approval rules
   - shipped/delivered logic
   - canceled logic
   - if approved_at is NULL → ALL other dates must be NULL
   ============================================================ */
check_status_based_null AS (
    SELECT *
    FROM check_null

    WHERE
    -- ===== Approval Rules =====
    (
         -- Statuses where approval MUST exist
        (order_status IN ('approved','delivered','invoiced','processing','unavailable','shipped')
            AND order_approved_at IS NOT NULL)

        -- 'created' must have no approval
        OR (order_status = 'created'
            AND order_approved_at IS NULL)

        -- Canceled: approval can exist or not → handled in delivery rules
        OR (order_status = 'canceled')
    )

    AND

    -- ===== Delivery Rules =====
    (
        -- If approval is NULL → ALL other date columns must be NULL
        (
            order_approved_at IS NULL 
            AND order_delivered_carrier_date IS NULL 
            AND order_delivered_customer_date IS NULL
        )

        -- Delivered must have both carrier & final customer delivery
        OR (order_status = 'delivered'
            AND order_delivered_carrier_date IS NOT NULL
            AND order_delivered_customer_date IS NOT NULL)

        -- Canceled → customer delivery must be NULL (carrier optional)
        OR (order_status = 'canceled'
            AND order_delivered_customer_date IS NULL)

        -- Shipped → carrier exists, customer not delivered yet
        OR (order_status = 'shipped'
            AND order_delivered_carrier_date IS NOT NULL
            AND order_delivered_customer_date IS NULL)

        -- Middle statuses must have no delivery timestamps
        OR (order_status IN ('approved','invoiced','processing','created','unavailable')
            AND order_delivered_carrier_date IS NULL
            AND order_delivered_customer_date IS NULL)
    )
),


/* ============================================================
   STEP 4: Fix timestamp inconsistencies
   - Ensures approved_at <= carrier_date <= customer_date
   - Prevents impossible chronological sequences
   ============================================================ */
check_date AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        flag,

        /* Fix 1: approved_at should never be after carrier_date */
        CASE
            WHEN order_approved_at IS NOT NULL
                 AND order_delivered_carrier_date IS NOT NULL
                 AND order_approved_at > order_delivered_carrier_date
            THEN order_delivered_carrier_date
            ELSE order_approved_at
        END AS order_approved_at,

        /* Fix 2: carrier_date should be between approval and customer delivery */
        CASE
            WHEN order_approved_at IS NOT NULL
                 AND order_delivered_carrier_date IS NOT NULL
                 AND order_approved_at > order_delivered_carrier_date
            THEN order_approved_at

            WHEN order_delivered_carrier_date IS NOT NULL
                 AND order_delivered_customer_date IS NOT NULL
                 AND order_delivered_carrier_date > order_delivered_customer_date
            THEN order_delivered_customer_date
            ELSE order_delivered_carrier_date
        END AS order_delivered_carrier_date,

        /* Fix 3: customer_date must be the final/latest timestamp */
        CASE
            WHEN order_delivered_carrier_date IS NOT NULL
                 AND order_delivered_customer_date IS NOT NULL
                 AND order_delivered_carrier_date > order_delivered_customer_date
            THEN order_delivered_carrier_date
            ELSE order_delivered_customer_date
        END AS order_delivered_customer_date,

        order_estimated_delivery_date 

    FROM check_status_based_null
)


/* ============================================================
   STEP 5: Insert only the first row per order after cleaning
   ============================================================ */
INSERT INTO silver_BE.olist_orders_dataset (
    order_id ,
    customer_id ,
    order_status ,
    order_purchase_timestamp ,
    order_approved_at ,
    order_delivered_carrier_date ,
    order_delivered_customer_date ,
    order_estimated_delivery_date 
)
SELECT 
    order_id ,
    customer_id ,
    order_status ,
    order_purchase_timestamp ,
    order_approved_at ,
    order_delivered_carrier_date ,
    order_delivered_customer_date ,
    order_estimated_delivery_date 
FROM check_date
WHERE flag = 1;
GO




---------------------------- VALIDATION CHECKS ----------------------------

-- Check unique order_id (expected 0)
SELECT DISTINCT order_status FROM silver_BE.olist_orders_dataset;


-- Compare row counts between bronze and silver
SELECT
    (SELECT COUNT(*) FROM silver_BE.olist_orders_dataset) AS silver_BE_table,
    (SELECT COUNT(*) FROM bronze_BE.olist_orders_dataset) AS bronze_BE_table,
    (SELECT COUNT(*) FROM bronze_BE.olist_orders_dataset) - 
    (SELECT COUNT(*) FROM silver_BE.olist_orders_dataset)  AS diff;



-- Check duplicate orders after cleaning (expected 0)
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_purchase_timestamp) AS flag
    FROM silver_BE.olist_orders_dataset
) t
WHERE flag > 1;



-- Essential null check (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE customer_id IS NULL
  AND order_status IS NULL;



-- Approval must not be null for these statuses (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status IN ('approved','delivered','invoiced','shipped','processing','unavailable') 
  AND order_approved_at IS NULL;



-- Delivered must have all delivery timestamps (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status = 'delivered'
  AND (order_delivered_carrier_date IS NULL OR order_delivered_customer_date IS NULL);



-- Shipped must have carrier_date (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status = 'shipped'
  AND (order_delivered_carrier_date IS NULL);



-- Canceled must not have customer delivery (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status = 'canceled'
  AND order_delivered_customer_date IS NOT NULL;



-- Middle statuses must have no delivery timestamps AND must have approval (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status IN ('unavailable','processing')
  AND order_delivered_carrier_date IS NULL 
  AND order_delivered_customer_date IS NULL
  AND order_approved_at IS NULL;



-- canceled AND carrier_date exists BUT no approval (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status = 'canceled'
     AND order_delivered_carrier_date IS NOT NULL 
     AND order_approved_at IS NULL;



-- Impossible condition check (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_approved_at IS NULL
     AND order_delivered_carrier_date IS NOT NULL 
     AND order_approved_at IS NOT NULL;



-- canceled cannot have customer delivery (expected 0)
SELECT *
FROM silver_BE.olist_orders_dataset
WHERE order_status ='canceled' 
  AND order_delivered_customer_date IS NOT NULL;