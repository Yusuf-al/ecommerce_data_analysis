/*
SELLER PERFORMANCE SCORING AND TIERING ANALYSIS
Purpose: Evaluate seller performance across multiple dimensions and assign a composite score
Expected Outcome: Ranked list of sellers with performance metrics, percentiles, and tier classification
Business Use: Identify top performers, segment sellers for targeted support, and track velocity metrics
*/

WITH saller_base AS (
    -- BASE METRICS: Calculate foundational performance indicators for each seller
    -- Includes order volume, revenue, ratings, and activity timeframe
    SELECT 
        s.seller_custome_key as seller_key,
        COUNT(DISTINCT oi.order_custome_id) as total_orders,
        SUM(oi.item_price + oi.shipping_cost) as total_revenue,
        CAST(AVG(r.review_score) as DECIMAL(10,2)) as avg_rating,
        MAX(oi.purchase_date) as last_order,
        MIN(oi.purchase_date) as first_order
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_sellers s  
        ON oi.seller_custome_key = s.seller_custome_key
    LEFT JOIN gold_BE.fact_reviews r  
        ON r.seller_custome_key = oi.seller_custome_key
    WHERE oi.purchase_date IS NOT NULL 
    GROUP BY s.seller_custome_key
),

seller_valocity AS (
    -- VELOCITY CALCULATION: Measure activity intensity and operational speed
    -- Key metric: orders_per_day indicates sales tempo and seller engagement
    SELECT 
        seller_key,
        total_orders,
        total_revenue,
        avg_rating,
        DATEDIFF(DAY, first_order, last_order) as active_days,
        CASE 
            WHEN DATEDIFF(DAY, first_order, last_order) = 0 THEN total_orders
            ELSE CAST(total_orders * 1.0 / NULLIF(DATEDIFF(DAY, first_order, last_order), 0) as DECIMAL(10,2)) 
        END as 'orders_per_day'
    FROM saller_base
),

pacentile_ranking AS (
    -- STATISTICAL RANKING: Position sellers relative to peers across key dimensions
    -- Uses PERCENT_RANK for relative standing, RANK for absolute position, NTILE for quartile segmentation
    SELECT 
        seller_key,
        total_orders,
        total_revenue,
        avg_rating,
        orders_per_day,

        -- Relative performance percentiles (0-1 scale)
        PERCENT_RANK() OVER(ORDER BY total_revenue) as rev_pct,
        PERCENT_RANK() OVER(ORDER BY total_orders) as odr_pct,
        PERCENT_RANK() OVER(ORDER BY avg_rating) as rating_pct,
        PERCENT_RANK() OVER(ORDER BY total_orders) as per_day_odr_pct,

        -- Absolute ranking positions
        RANK() OVER(ORDER BY total_revenue) as rev_rank,
        RANK() OVER(ORDER BY avg_rating) as rating_rank,

        -- Quartile segmentation (1-4, where 4 is top quartile)
        NTILE(4) OVER(ORDER BY total_revenue) as rev_quartlie,
        NTILE(4) OVER(ORDER BY orders_per_day) as per_day_odr_quartlie
    FROM seller_valocity
),

casting_value AS (
    -- FORMATTING: Standardize decimal precision for consistent scoring
    SELECT 
        seller_key,
        total_orders,
        total_revenue,
        avg_rating,
        orders_per_day,
        CAST(rev_pct as DECIMAL(10,2)) revenue_pct,
        CAST(odr_pct as DECIMAL(10,2)) orders_pct,
        CAST(rating_pct as DECIMAL(10,2)) rating_pct,
        CAST(per_day_odr_pct as DECIMAL(10,2)) velocity_pct,
        rev_rank,
        rating_rank,
        rev_quartlie,
        per_day_odr_quartlie
    FROM pacentile_ranking 
),

weighted_scoring AS (
    -- COMPOSITE SCORING: Combine multiple metrics with business-weighted importance
    -- Revenue (40%), Orders (25%), Ratings (25%), Velocity (10%) = 100% total
    SELECT
        *,
        (
            (revenue_pct * 0.40) +
            (orders_pct * 0.25) +
            (rating_pct * 0.25) +
            (velocity_pct * 0.10)
        ) AS weighted_score
    FROM casting_value 
),

seller_grading AS (
    -- PERFORMANCE TIERING: Assign letter grades based on weighted score thresholds
    -- Creates actionable segmentation for different seller groups
    SELECT 
        *,
        CASE 
            WHEN weighted_score >= 0.85 THEN 'A+ (Top Performer)'
            WHEN weighted_score >= 0.70 THEN 'A'
            WHEN weighted_score >= 0.55 THEN 'B'
            WHEN weighted_score >= 0.40 THEN 'C'
            ELSE 'D (Underperforming)'
        END AS performance_tier
    FROM weighted_scoring
)

-- FINAL OUTPUT: Sorted by composite score and order volume
SELECT *
FROM seller_grading
ORDER BY weighted_score DESC, total_orders DESC;


/*
=================================================================================================
PRODUCT PERFORMANCE DECAY ANALYSIS
    Objective: Track how product performance changes over time after launch
    Purpose: Identify product lifecycle patterns and category-level revenue trends
    Expected Outcome: Monthly category revenue with launch context and yearly totals
    Business Use: Inventory planning, marketing strategy, and product lifecycle management
=================================================================================================
*/

WITH first_order_placed AS (
    -- LAUNCH IDENTIFICATION: Find first sale date for each product (product launch)
    -- Critical for tracking performance from initial market entry
    SELECT 
        p.product_custome_key as product_key,
        p.category_english_name,
        MIN(oi.purchase_date) as first_order
    FROM gold_BE.dim_products p   
    LEFT JOIN gold_BE.fact_order_items oi
        ON p.product_custome_key = oi.product_custome_key
    LEFT JOIN gold_BE.dim_orders o  
        ON oi.order_custome_id = o.order_custome_id
    GROUP BY p.product_custome_key, p.category_english_name
),

monthly_performace AS (
    -- MONTHLY PRODUCT PERFORMANCE: Revenue aggregation at product-month level
    -- Creates time-series data for tracking performance decay over time
    SELECT
        p.product_custome_key as product_key,
        p.category_english_name,
        FORMAT(oi.purchase_date, 'yyyy-MMM') as sales_month,
        SUM(oi.item_price + oi.shipping_cost) as monthly_revenue
    FROM gold_BE.dim_products p   
    LEFT JOIN gold_BE.fact_order_items oi
        ON p.product_custome_key = oi.product_custome_key
    LEFT JOIN gold_BE.dim_orders o  
        ON oi.order_custome_id = o.order_custome_id
    GROUP BY p.product_custome_key, 
             p.category_english_name,
             FORMAT(oi.purchase_date, 'yyyy-MMM')
),

performance_with_launch AS (
    -- LAUNCH CONTEXT ADDITION: Combine monthly performance with launch date
    -- Enables calculation of time since launch for each monthly data point
    SELECT
        mp.product_key,
        mp.category_english_name,
        mp.sales_month,
        mp.monthly_revenue,
        fp.first_order 
    FROM monthly_performace mp 
    LEFT JOIN first_order_placed fp 
        ON mp.product_key = fp.product_key
),

monthly_category_revenue AS (
    -- CATEGORY-LEVEL AGGREGATION: Roll up from product to category level
    -- Shows overall category performance trends by month
    SELECT 
        category_english_name,
        sales_month,
        first_order,
        SUM(monthly_revenue) as category_monthly_revenue
    FROM performance_with_launch
    GROUP BY category_english_name,
             sales_month,
             first_order
),

category_yearly AS (
    -- YEARLY CATEGORY TOTALS: Annual revenue aggregation for context
    -- Provides benchmark for monthly performance evaluation
    SELECT
        category_english_name,
        YEAR(sales_month) AS sale_year,
        SUM(category_monthly_revenue) AS category_yearly_revenue
    FROM monthly_category_revenue
    GROUP BY 
        category_english_name,
        YEAR(sales_month)
)

-- FINAL OUTPUT: Category performance with monthly, yearly, and launch context
SELECT 
    cm.category_english_name,
    cm.sales_month,
    cm.first_order,
    cm.category_monthly_revenue,
    cy.category_yearly_revenue
FROM monthly_category_revenue cm
LEFT JOIN category_yearly cy
    ON cy.category_english_name = cm.category_english_name
    AND cy.sale_year = YEAR(cm.sales_month)
ORDER BY 
    cm.category_english_name,
    cm.sales_month;