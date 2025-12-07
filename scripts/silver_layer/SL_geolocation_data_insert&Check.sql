
TRUNCATE TABLE silver_BE.olist_geolocation_dataset;

-- Insert cleaned and deduplicated geolocation data
INSERT INTO silver_BE.olist_geolocation_dataset(
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state 
) 

SELECT 
     RIGHT(REPLICATE(0, 5) + CAST(geolocation_zip_code_prefix AS VARCHAR(5)), 5) AS geolocation_zip_code_prefix,
     TRIM(geolocation_lat),
     TRIM(geolocation_lng),
     TRIM(geolocation_city),
     TRIM(geolocation_state) 
FROM(

    -- Deduplicate by unique location coordinates
    SELECT *,
            ROW_NUMBER() OVER(
            PARTITION BY geolocation_zip_code_prefix, geolocation_lat,geolocation_lng  
            ORDER BY geolocation_lat) as flag
    FROM bronze_BE.olist_geolocation_dataset

    -- Filter out records with missing critical geolocation data
    WHERE geolocation_zip_code_prefix IS NOT NULL OR geolocation_zip_code_prefix != ''
        OR geolocation_lat IS NOT NULL OR geolocation_lat != ''
        OR geolocation_lng IS NOT NULL OR geolocation_lng != ''
        OR geolocation_city IS NOT NULL OR geolocation_city != ''
        OR geolocation_state IS NOT NULL OR geolocation_state != ''
)t  WHERE flag = 1 



----- DATA QUALITY CHECK: Verify no duplicate coordinates remain
----- Expected result: Zero rows
SELECT * 

FROM (
    SELECT *,
            ROW_NUMBER() OVER(
            PARTITION BY geolocation_zip_code_prefix, geolocation_lat,geolocation_lng  
            ORDER BY geolocation_lat) as flag
    FROM silver_BE.olist_geolocation_dataset
)t WHERE flag > 1 



----- DATA QUALITY CHECK: Verify all whitespace has been trimmed and no empty/NULL critical fields
----- Expected result: Zero rows
SELECT *
FROM silver_BE.olist_geolocation_dataset
WHERE geolocation_lat != TRIM(geolocation_lat) OR geolocation_lat = '' OR geolocation_lat IS NULL
OR geolocation_lng != TRIM(geolocation_lng) OR geolocation_lng ='' OR geolocation_lng IS NULL
OR geolocation_city != TRIM(geolocation_city) OR geolocation_city ='' OR geolocation_city IS NULL
OR geolocation_state != TRIM(geolocation_state) OR geolocation_state ='' OR geolocation_state IS NULL

SELECT * FROM silver_BE.olist_geolocation_dataset
WHERE len(geolocation_zip_code_prefix) < 5

--- check white s
