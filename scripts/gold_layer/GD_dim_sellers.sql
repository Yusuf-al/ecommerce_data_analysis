IF OBJECT_ID('gold_BE.dim_sellers','V') IS NOT NULL
    DROP VIEW gold_BE.dim_sellers;
GO

CREATE VIEW gold_BE.dim_sellers AS 
    SELECT 
        ROW_NUMBER() OVER(ORDER BY seller_state) as seller_custome_key,
        seller_id,
        seller_zip_code_prefix as seller_zip_code,
        seller_city,
        seller_state
    FROM silver_BE.olist_sellers_dataset
GO

SELECT *FROM gold_BE.dim_sellers
-- GROUP BY seller_id,seller_city,seller_zip_code,seller_state
-- HAVING COUNT(*) > 1


SELECT * FROM silver_BE.olist_sellers_dataset s  
LEFT JOIN silver_BE.olist_order_items_dataset  oi  
ON s.seller_id = oi.seller_id
WHERE s.seller_id is NULL