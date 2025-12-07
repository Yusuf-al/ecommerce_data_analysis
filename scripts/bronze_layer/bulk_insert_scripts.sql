TRUNCATE TABLE bronze_BE.olist_customers_dataset
BULK INSERT bronze_BE.olist_customers_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_customers_dataset_c22.csv'
WITH (
    FORMAT='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-------------------------------------------------------------------------------------------------------------------------

TRUNCATE TABLE bronze_BE.olist_geolocation_dataset
BULK INSERT bronze_BE.olist_geolocation_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_geolocation_dataset_2.csv'
WITH (
     FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001',   -- ✅ This makes it read UTF-8 correctly
    TABLOCK
);


-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_order_items_dataset
BULK INSERT bronze_BE.olist_order_items_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_order_items_dataset_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)


-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_order_payments_dataset
BULK INSERT bronze_BE.olist_order_payments_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_order_payments_dataset_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)


-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_order_reviews_dataset
BULK INSERT bronze_BE.olist_order_reviews_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_order_reviews_dataset_c.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)


-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_orders_dataset
BULK INSERT bronze_BE.olist_orders_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_orders_dataset_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)


-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_products_dataset
BULK INSERT bronze_BE.olist_products_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_products_dataset_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)

-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.olist_sellers_dataset
BULK INSERT bronze_BE.olist_sellers_dataset
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\olist_sellers_dataset_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    CODEPAGE = '65001',   -- ✅ This makes it read UTF-8 correctly
    TABLOCK
)



-------------------------------------------------------------------------------------------------------------------------
TRUNCATE TABLE bronze_BE.product_category_name_translation
BULK INSERT bronze_BE.product_category_name_translation
FROM 'C:\Users\Yusuf Al Naiem\OneDrive\Desktop\SQL Data\Project-4-Brazilian-EC\product_category_name_translation_2.csv'
WITH (
    FORMAT ='CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR =',',
    TABLOCK
)



