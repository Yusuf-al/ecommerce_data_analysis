/********************************************************************************************
FACT TABLE: gold_BE.fact_payments
Purpose:
- Store payment-related metrics for each customer order.
- One row per payment record (an order may have multiple payments).
- Connects to Order and Customer dimensions to support BI reporting on:
        ✔ Payment type trends
        ✔ Installment behavior
        ✔ Payment amounts by customer or region

Expected Outcome:
- Fact table containing financial measures linked to dimensions.
- Allows slicing analysis by order, customer, date, and payment types.
********************************************************************************************/

-- Remove existing view if it already exists
IF OBJECT_ID('gold_BE.fact_payments','V') IS NOT NULL
    DROP VIEW gold_BE.fact_payments;
GO


CREATE VIEW gold_BE.fact_payments AS

/* STEP 1: Collect raw payment + order-level information */
WITH base_payments AS (
    SELECT
        po.order_id,
        po.payment_sequential,
        po.payment_installments,
        po.payment_type,
        po.payment_value,

        -- Located from order dimension
        od.order_custome_id AS order_custome_id,
        order_custome_id  as customer_id,

        od.purchase_date AS payment_date
    FROM silver_BE.olist_order_payments_dataset po  
    LEFT JOIN gold_BE.dim_orders od 
        ON po.order_id = od.order_id 
    WHERE od.order_id IS NOT NULL
),

/* STEP 2: Add customer foreign key from customer dimension */
attach_customers AS (
    SELECT 
        bp.*,
        
        /* If customer not found in dimension, assign default surrogate key */
        COALESCE(ci.customer_custome_key, -1) AS customer_custome_key
    FROM base_payments bp 
    LEFT JOIN gold_BE.dim_customers ci 
        ON bp.customer_id = ci.customer_custome_key
)

/* Final fact selection */
SELECT 
    ROW_NUMBER() OVER (ORDER BY order_id, payment_sequential) AS payment_custome_key,  -- Surrogate key

    order_custome_id,
    customer_custome_key,

    payment_sequential,
    payment_installments,
    payment_value,
    payment_type,
    payment_date

FROM attach_customers;
GO

-- Review data
SELECT TOP 20 * FROM gold_BE.fact_payments;
