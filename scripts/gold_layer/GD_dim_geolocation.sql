/********************************************************************************************
DIMENSION TABLE: gold_BE.dim_geo_location
Purpose:
- Create a geography dimension for all valid city–state–ZIP combinations.
- Standardize missing values by combining customer master and geolocation files.
- Deduplicate records so BI tools can join consistently (1 row per unique location).

Expected Outcome:
- Each row represents a unique City + State + ZIP combination.
- Contains a surrogate key (loc_custome_key) for dimension joins from facts.
********************************************************************************************/

-- Drop existing view if it already exists
IF OBJECT_ID('gold_BE.dim_geo_location','V') IS NOT NULL
    DROP VIEW gold_BE.dim_geo_location;
GO


-- Create the Dimension View
CREATE VIEW gold_BE.dim_geo_location AS
SELECT
    -- Surrogate key for star-schema joins
    ROW_NUMBER() OVER (ORDER BY geolocation_state) AS loc_custome_key,

    -- Standardized output fields
    geolocation_city,
    geolocation_state,
    location_zip_code

FROM (
    /* STEP 3: Select only the first record per unique city-state-ZIP combination */
    SELECT 
        inner_data.*,
        ROW_NUMBER() OVER (
            PARTITION BY 
                inner_data.geolocation_city,
                inner_data.geolocation_state,
                inner_data.location_zip_code
            ORDER BY inner_data.location_zip_code
        ) AS flag
    FROM (

        /* STEP 2: Standardize missing geo fields by combining both datasets */
        SELECT 
            -- City: Prefer geolocation dataset, else customer dataset
            COALESCE(g.geolocation_city, c.customer_city) AS geolocation_city,

            -- State: Prefer geolocation dataset, else customer dataset
            COALESCE(g.geolocation_state, c.customer_state) AS geolocation_state,

            -- ZIP: Choose the correct source based on best match available
            CASE 
                WHEN c.customer_city = g.geolocation_city
                 AND c.customer_state = g.geolocation_state
                 AND c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
                    THEN c.customer_zip_code_prefix

                WHEN g.geolocation_zip_code_prefix IS NULL
                    THEN c.customer_zip_code_prefix

                WHEN c.customer_zip_code_prefix IS NULL
                    THEN g.geolocation_zip_code_prefix

                ELSE g.geolocation_zip_code_prefix
            END AS location_zip_code

        FROM silver_BE.olist_customers_dataset c
        LEFT JOIN silver_BE.olist_geolocation_dataset g
            ON g.geolocation_zip_code_prefix = c.customer_zip_code_prefix
    ) inner_data
) final_data

WHERE flag = 1;   -- Keep only unique records

GO


-- View sample data
SELECT TOP 20 * FROM gold_BE.dim_geo_location;
