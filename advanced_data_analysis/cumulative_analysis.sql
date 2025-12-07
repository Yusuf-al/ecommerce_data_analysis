/* ======================================================
   RUNNING TOTAL REVENUE ANALYSIS  
   Objective: Track cumulative revenue trend and 
   calculate running totals & running averages
====================================================== */

-------------------------------------------------------------------------------
-- RUNNING TOTAL REVENUE ANALYSIS
-- Purpose: Calculate cumulative revenue metrics across multiple time periods
-- This analysis helps track progressive revenue accumulation and daily averages
-------------------------------------------------------------------------------

GO   

WITH daily_revenue AS (
    -- CTE 1: Aggregate daily revenue from order items
    -- Calculates total revenue for each calendar day
    SELECT
        oi.purchase_date as order_date,
        SUM(total_order_cost) as daily_revenue
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_orders o  
        ON oi.order_custome_id = o.order_custome_id
    WHERE oi.purchase_date IS NOT NULL
    GROUP BY oi.purchase_date
),

date_breakdown AS (
    -- CTE 2: Extract time period components for hierarchical analysis
    -- Breaks down each date into year, month, and quarter for multi-level aggregation
    SELECT
        order_date,
        daily_revenue,
        YEAR(order_date) AS order_year,
        FORMAT(order_date, 'yyyy-MM') AS order_month,
        CONCAT('Q', DATEPART(QUARTER, order_date)) AS order_quarter
    FROM daily_revenue
),

running_totals AS (
    -- CTE 3: Calculate running/cumulative totals using window functions
    -- Four different cumulative calculations provide multi-perspective trend analysis
    SELECT
        order_date,
        order_year,
        order_month,
        order_quarter,
        daily_revenue,
        
        -- Running total within each month: resets at the start of each month
        SUM(daily_revenue) OVER (
            PARTITION BY order_month
            ORDER BY order_date
        ) AS running_monthly_total,
        
        -- Running total within each quarter: tracks cumulative revenue per quarter
        SUM(daily_revenue) OVER (
            PARTITION BY order_year, order_quarter
            ORDER BY order_date
        ) AS running_quarterly_total,
        
        -- Running total within each year: tracks year-to-date revenue
        SUM(daily_revenue) OVER (
            PARTITION BY order_year
            ORDER BY order_date
        ) AS running_yearly_total,
        
        -- Running average within each year: calculates average daily revenue year-to-date
        AVG(daily_revenue) OVER (
            PARTITION BY order_year
            ORDER BY order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_avg_revenue
    FROM date_breakdown
)

-- Final SELECT: Output all calculated running metrics
SELECT 
    order_date,
    order_year,
    order_month,
    order_quarter,
    daily_revenue,
    running_monthly_total,
    running_quarterly_total,
    running_yearly_total,
    running_avg_revenue
FROM running_totals
ORDER BY order_date;


--===============================================================================================================================
/*
YEAR-TO-DATE SALES PERFORMANCE ANALYSIS
Purpose: Compare current year (2018) YTD performance against prior year (2017) YTD
Expected Outcome: Single row showing 2018 vs 2017 metrics with variances for:
                  - Revenue
                  - Order count  
                  - New customer acquisition
Business Use: Track growth trends and measure year-over-year performance
*/

-- Base dataset: Combine order items with customer information
WITH base AS (
    SELECT
        oi.order_custome_id,
        o.customer_custome_key,
        oi.purchase_date,
        YEAR(oi.purchase_date) AS order_year,
        MONTH(oi.purchase_date) AS order_month,
        total_order_cost
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_orders o 
        ON oi.order_custome_id = o.order_custome_id
),

-- Identify first purchase date for each customer (for new customer calculation)
first_order AS (
    SELECT
        customer_custome_key,
        MIN(purchase_date) AS first_order_date
    FROM base 
    GROUP BY customer_custome_key
),

-- CURRENT YEAR (2018) YTD metrics calculation
-- Note: Using fixed date '2018-12-31' to calculate full year YTD
ytd_current AS (
    SELECT 
        b.order_year,

        -- Total revenue for current year up to Dec 31, 2018
        SUM(CASE 
                WHEN b.purchase_date <= CAST('2018-12-31' AS DATE) 
                THEN b.total_order_cost 
            END) AS ytd_revenue,

        -- Total orders for current year up to Dec 31, 2018
        COUNT(CASE 
                WHEN b.purchase_date <= CAST('2018-12-31' AS DATE) 
                THEN b.order_custome_id 
            END) AS ytd_orders,

        -- New customers acquired in current year YTD
        COUNT(CASE 
                WHEN fo.first_order_date = b.purchase_date 
                     AND b.purchase_date <= CAST('2018-12-31' AS DATE)
                THEN b.customer_custome_key 
            END) AS ytd_new_customers

    FROM base b  
    LEFT JOIN first_order fo  
        ON fo.customer_custome_key = b.customer_custome_key
    WHERE b.order_year = 2018
    GROUP BY b.order_year
),

-- PRIOR YEAR (2017) YTD metrics calculation
-- Note: Comparing same period (up to day 365) for year-over-year comparison
ytd_prior AS (
    SELECT 
        b.order_year AS prior_year,

        -- Prior year revenue for same YTD period (up to day 365)
        SUM(CASE
                WHEN DATEPART(DAYOFYEAR, b.purchase_date) 
                     <= DATEPART(DAYOFYEAR, CAST('2018-12-31' AS DATE)) 
                THEN b.total_order_cost
            END) AS pytd_revenue,

        -- Prior year orders for same YTD period
        COUNT(CASE 
                WHEN DATEPART(DAYOFYEAR, b.purchase_date) 
                     <= DATEPART(DAYOFYEAR, CAST('2018-12-31' AS DATE)) 
                THEN b.order_custome_id
            END) AS pytd_orders,

        -- New customers acquired in prior year during same period
        COUNT(CASE 
                WHEN fo.first_order_date = b.purchase_date 
                     AND DATEPART(DAYOFYEAR, b.purchase_date) 
                         <= DATEPART(DAYOFYEAR, CAST('2018-12-31' AS DATE))
                THEN b.customer_custome_key
            END) AS pytd_new_customers
    FROM base b
    LEFT JOIN first_order fo 
        ON b.customer_custome_key = fo.customer_custome_key
    WHERE b.order_year = 2017
    GROUP BY b.order_year
)

-- FINAL RESULTS: Side-by-side comparison with variance calculations
SELECT 
    c.order_year,
    c.ytd_revenue,
    c.ytd_orders,
    c.ytd_new_customers,

    p.prior_year,
    p.pytd_revenue,
    p.pytd_orders,
    p.pytd_new_customers,

    -- Performance variances (Current Year - Prior Year)
    (c.ytd_revenue - p.pytd_revenue) AS revenue_variance,
    (c.ytd_orders - p.pytd_orders) AS orders_variance,
    (c.ytd_new_customers - p.pytd_new_customers) AS new_customer_variance
FROM ytd_current c  
LEFT JOIN ytd_prior p  
    ON c.order_year - 1 = p.prior_year;