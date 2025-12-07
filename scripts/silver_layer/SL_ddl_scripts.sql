IF OBJECT_ID('silver_BE.olist_customers_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_customers_dataset;

CREATE TABLE silver_BE.olist_customers_dataset (
    customer_id NVARCHAR(100),
    customer_unique_id NVARCHAR(100),
    customer_zip_code_prefix NVARCHAR(50),
    customer_city NVARCHAR(50),
    customer_state NVARCHAR(50),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

-------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_geolocation_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_geolocation_dataset;

CREATE TABLE silver_BE.olist_geolocation_dataset (
    geolocation_zip_code_prefix NVARCHAR(50),
    geolocation_lat NVARCHAR(50),
    geolocation_lng NVARCHAR(50),
    geolocation_city NVARCHAR(50),
    geolocation_state NVARCHAR(50),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

--------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_order_items_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_order_items_dataset;

CREATE TABLE silver_BE.olist_order_items_dataset (
    order_id CHAR(32),
    order_item_id INT,
    product_id CHAR(32),
    seller_id CHAR(32),
    shipping_limit_date DATETIME2,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

----------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_order_payments_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_order_payments_dataset;

CREATE TABLE silver_BE.olist_order_payments_dataset(
    order_id CHAR(32),
    payment_sequential INT,
    payment_type NVARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10,2),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

----------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_order_reviews_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_order_reviews_dataset;
    
CREATE TABLE silver_BE.olist_order_reviews_dataset (
    review_id CHAR(32),
    order_id CHAR(32),
    review_score INT,
    review_creation_date DATETIME2,
    review_answer_timestamp DATETIME2,
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

--------------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_orders_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_orders_dataset;

CREATE TABLE silver_BE.olist_orders_dataset(
    order_id CHAR(32),
    customer_id CHAR(32),
    order_status NVARCHAR(50),
    order_purchase_timestamp DATETIME2,
    order_approved_at DATETIME2,
    order_delivered_carrier_date DATETIME2,
    order_delivered_customer_date DATETIME2,
    order_estimated_delivery_date DATETIME2,
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

---------------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_products_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_products_dataset;

CREATE TABLE silver_BE.olist_products_dataset(
    product_id CHAR(32),
    product_category_name NVARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

------------------------------------------------------------------------------
IF OBJECT_ID('silver_BE.olist_sellers_dataset','U') IS NOT NULL
    DROP TABLE silver_BE.olist_sellers_dataset;

CREATE TABLE silver_BE.olist_sellers_dataset(
    seller_id CHAR(32),
    seller_zip_code_prefix NVARCHAR(50),
    seller_city NVARCHAR(50),
    seller_state NVARCHAR(50),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)

---------------------------------------------------------------------------------
IF OBJECT_ID('silver_BE.product_category_name_translation','U') IS NOT NULL
    DROP TABLE silver_BE.product_category_name_translation;

CREATE TABLE silver_BE.product_category_name_translation(
    product_category_name NVARCHAR(100) ,
    product_category_name_english NVARCHAR(100),
    dwh_created_date DATETIME2 DEFAULT GETDATE()
)