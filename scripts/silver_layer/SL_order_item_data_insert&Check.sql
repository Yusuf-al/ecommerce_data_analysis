
---------------------------------------------------------------
-- STEP 1: Clear existing data in the Silver Layer table
---------------------------------------------------------------
TRUNCATE TABLE silver_BE.olist_order_items_dataset

---------------------------------------------------------------
-- STEP 2: Insert cleaned and deduplicated order item records
---------------------------------------------------------------
INSERT INTO silver_BE.olist_order_items_dataset (
    order_id ,
    order_item_id ,
    product_id ,
    seller_id ,
    shipping_limit_date ,
    price,
    freight_value 
) 
    SELECT 
        TRIM(order_id) as order_id ,
        order_item_id ,
        TRIM(product_id) as product_id ,
        TRIM(seller_id) as seller_id ,
        shipping_limit_date ,
        ROUND(CAST(price as DECIMAL(10,2)),2) as price,
        ROUND(CAST(freight_value as DECIMAL(10,2)),2) as freight_value 
    FROM (

        SELECT
            *,
            ROW_NUMBER() OVER(PARTITION BY
                                    order_id, 
                                    product_id, 
                                    price,
                                    freight_value ORDER BY shipping_limit_date) AS flag
        FROM bronze_BE.olist_order_items_dataset
        WHERE freight_value < 2*price 
            AND price > -1 AND price is NOT NULL
            AND order_id IS NOT NULL AND order_id != '' 
            AND product_id IS NOT NULL AND product_id != '' 
            AND seller_id IS NOT NULL AND seller_id != '' 
            AND shipping_limit_date IS NOT NULL AND shipping_limit_date  != '' 
            AND shipping_limit_date < GETDATE()
    )t WHERE flag = 1 


---------------------------------------------------------------
-- STEP 3: Data Quality Check — Duplicates
------------ Expected result: Zero rows------------------------

SELECT * FROM (

SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY order_id, 
                                    product_id, 
                                    price,
                                    seller_id,
                                    freight_value 
                                    ORDER BY shipping_limit_date) as flag
FROM silver_BE.olist_order_items_dataset
)t WHERE flag > 1

---------------------------------------------------------------
-- STEP 3: Data Quality Checks
---------------------------------------------------------------
----====== EXPECTED OUT COME ZERO ROWS =========--------

--- order id is null or not
SELECT * FROM silver_BE.olist_order_items_dataset
WHERE order_id IS NULL

--- product ID is null or not
SELECT * FROM silver_BE.olist_order_items_dataset
WHERE product_id IS NULL

-- seller id null or Not
SELECT * FROM silver_BE.olist_order_items_dataset
WHERE seller_id IS NULL


-- freight_value should not be higher than 2x Price
SELECT * FROM silver_BE.olist_order_items_dataset
WHERE freight_value > 2 * price

-- Duplicate check
SELECT order_id, COUNT(*) AS duplicate_count
FROM silver_BE.olist_order_items_dataset
GROUP BY order_id, order_item_id, product_id, seller_id
HAVING COUNT(*) > 1;

-- Null check summary
SELECT 
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id
FROM silver_BE.olist_order_items_dataset;