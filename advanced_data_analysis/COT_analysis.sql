/*
================================================================================
CHANGE-OVER-TIME ANALYSIS - MASTER SCRIPT
================================================================================

OVERVIEW:
This collection of SQL queries provides comprehensive time-series analysis of business 
performance across three critical dimensions: revenue trends, customer behavior, and 
product seasonality. Together, they enable data-driven decision making for strategic 
planning and operational optimization.

ANALYSIS FRAMEWORK:
1. REVENUE TREND ANALYSIS 
2. CUSTOMER LIFECYCLE ANALYSIS 
3. PRODUCT SEASONALITY ANALYSIS 

BUSINESS OBJECTIVES:
- Track financial performance growth over time
- Understand customer acquisition and retention patterns
- Identify seasonal demand fluctuations for inventory planning
- Support forecasting, budgeting, and strategic planning

*/

-------------------------------------------------------------------------------
-- CHANGE-OVER-TIME ANALYSIS (Trends)
-- Objective: Calculate month-over-month revenue growth percentage for the past 12 months
-------------------------------------------------------------------------------

-- First Query: Monthly Revenue Growth Analysis
WITH MonthlyRevenue AS (
    -- CTE 1: Aggregate monthly revenue metrics
    SELECT
        YEAR(purchase_date) as revenue_year,
        MONTH(purchase_date) as revenue_month,
        FORMAT(purchase_date, 'yyy-MMM') as year_month,
        SUM(total_order_cost) as monthly_revenue,
        COUNT(DISTINCT order_custome_id) as monthly_orders,
        COUNT(DISTINCT product_custome_key) as unique_products_sold
    FROM gold_BE.fact_order_items
    WHERE purchase_date IS NOT NULL
    GROUP BY 
        YEAR(purchase_date),
        MONTH(purchase_date),
        FORMAT(purchase_date, 'yyy-MMm')
),

RevenueLag AS (
    -- CTE 2: Get previous month's metrics using LAG window function
    SELECT 
        *, 
        LAG(monthly_revenue, 1) OVER(ORDER BY revenue_year, revenue_month) as previous_month_revenue,
        LAG(monthly_orders, 1) OVER(ORDER BY revenue_year, revenue_month) as previous_month_orders
    FROM MonthlyRevenue
),

monthly_growth AS (
    -- CTE 3: Calculate month-over-month growth percentage
    SELECT
        *,
        CASE 
            WHEN previous_month_revenue = 0 OR previous_month_revenue IS NULL THEN NULL
            ELSE ROUND(((monthly_revenue - previous_month_revenue) * 100 / previous_month_revenue), 2)
        END as 'revenue_growth_percentage'
    FROM RevenueLag
)

-- Final SELECT: Display monthly revenue growth metrics
SELECT 
    revenue_year,
    revenue_month,
    monthly_revenue,
    previous_month_revenue,
    CAST(revenue_growth_percentage as decimal(10,2)) as revenue_growth_percentage
FROM monthly_growth 
ORDER BY 
    revenue_year ASC,
    revenue_month ASC;

-------------------------------------------------------------------------------
-- Yearly Revenue Growth Analysis
-- Objective: Calculate year-over-year revenue growth percentage
-------------------------------------------------------------------------------

WITH yearly_revenue AS (
    -- CTE 1: Aggregate yearly revenue totals
    SELECT
        YEAR(purchase_date) as revenue_year,
        SUM(total_order_cost) as total_yearly_revenue
    FROM gold_BE.fact_order_items 
    WHERE purchase_date is NOT NULL
    GROUP BY 
        YEAR(purchase_date)
),

yearly_lag AS (
    -- CTE 2: Get previous year's revenue using LAG function
    SELECT
        *,
        LAG(total_yearly_revenue, 1) OVER(ORDER BY revenue_year) as previous_year_revenue
    FROM yearly_revenue
)

-- Final SELECT: Calculate and display yearly growth percentage
SELECT 
    *,
    CASE 
        WHEN previous_year_revenue = 0 AND previous_year_revenue IS NULL THEN NULL
        ELSE CAST(ROUND(((total_yearly_revenue - previous_year_revenue) * 100 / previous_year_revenue), 2) as DECIMAL(10,2))
    END as 'yearly_growth'
FROM yearly_lag;



-------------------------------------------------------------------------------
-- CUSTOMER ACQUISITION & RETENTION COHORT ANALYSIS
-- Purpose: Track new customer acquisition and retention rates over time
-------------------------------------------------------------------------------

WITH first_order AS (
    -- Step 1: Identify each customer's first purchase date
    SELECT 
        customer_custome_key,
        MIN(purchase_date) as first_order 
    FROM gold_BE.dim_orders
    GROUP BY customer_custome_key
),

cohort_base AS (
    -- Step 2: Create cohorts based on the month of first purchase
    SELECT 
        customer_custome_key,
        FORMAT(first_order, 'yyyy-MM') as cohort_month,
        first_order
    FROM first_order
),

customer_activity AS (
    -- Step 3: Get all purchase activity for each customer
    SELECT 
        c.customer_custome_key,
        c.cohort_month,
        c.first_order,
        o.purchase_date as activity_date
    FROM cohort_base c  
    LEFT JOIN gold_BE.dim_orders o 
        ON c.customer_custome_key = o.customer_custome_key
),

retention_flags AS (
    -- Step 4: Flag customers retained at 30, 60, and 90-day intervals
    SELECT 
        cohort_month,
        customer_custome_key,
        MIN(CASE 
            WHEN activity_date >= first_order
            AND activity_date < DATEADD(DAY, 30, first_order)
            THEN 1 
        END) AS retained_30,
        
        MIN(CASE 
            WHEN activity_date >= DATEADD(DAY, 30, first_order)
            AND activity_date < DATEADD(DAY, 60, first_order)
            THEN 1 
        END) AS retained_60,
        
        MIN(CASE 
            WHEN activity_date >= DATEADD(DAY, 60, first_order)
            AND activity_date < DATEADD(DAY, 90, first_order)
            THEN 1 
        END) AS retained_90
    FROM customer_activity
    GROUP BY cohort_month, customer_custome_key
),

final_output AS (
    -- Step 5: Calculate retention percentages for each cohort
    SELECT 
        cohort_month,
        COUNT(customer_custome_key) as new_customer,
        CAST(ROUND(SUM(COALESCE(retained_30, 0)) * 100.0 / COUNT(customer_custome_key), 2) 
            as decimal(10, 2)) AS retention_30_day,
        CAST(ROUND(SUM(COALESCE(retained_60, 0)) * 100.0 / COUNT(customer_custome_key), 2) 
            as decimal(10, 2)) AS retention_60_day,
        CAST(ROUND(SUM(COALESCE(retained_90, 0)) * 100.0 / COUNT(customer_custome_key), 2) 
            as decimal(10, 2)) AS retention_90_day
    FROM retention_flags
    GROUP BY cohort_month
)

-- Final Output: Cohort analysis table
SELECT * 
FROM final_output
ORDER BY cohort_month;


-------------------------------------------------------------------------------
-- SEASONAL PRODUCT DEMAND ANALYSIS
-- Purpose: Analyze monthly sales patterns to identify seasonal trends
-------------------------------------------------------------------------------

WITH monthly_cat_sales AS (
    -- Step 1: Aggregate monthly sales data by product category
    -- This provides the foundational dataset for seasonal analysis
    SELECT 
        p.category_english_name,
        FORMAT(oi.purchase_date, 'yyyy-MM') as sales_month,
        SUM(oi.total_order_cost) as monthly_revenue,
        SUM(oi.order_quantity) as total_unit_sales   
    FROM gold_BE.fact_order_items oi 
    LEFT JOIN gold_BE.dim_products p 
        ON oi.product_custome_key = p.product_custome_key  
    LEFT JOIN gold_BE.dim_orders o  
        ON o.order_custome_id = oi.order_custome_id
    WHERE oi.purchase_date IS NOT NULL
    GROUP BY 
        p.category_english_name,
        FORMAT(oi.purchase_date, 'yyyy-MM')
),

seasonal_cal AS (
    -- Step 2: Calculate month-over-month growth for each category
    -- Uses LAG() window function to compare with previous month
    SELECT
        category_english_name,
        sales_month,
        monthly_revenue,
        total_unit_sales,
        LAG(monthly_revenue, 1) OVER (
            PARTITION BY category_english_name 
            ORDER BY sales_month
        ) as previous_month_revenue,
        
        -- Calculate percentage growth with NULLIF to avoid division by zero
        CAST(ROUND(
            (monthly_revenue - LAG(monthly_revenue, 1) 
                OVER (PARTITION BY category_english_name ORDER BY sales_month))
            / NULLIF(LAG(monthly_revenue, 1) 
                OVER (PARTITION BY category_english_name ORDER BY sales_month), 0)
            * 100, 2
        ) as decimal(10, 2)) AS mom_growth_percent
    FROM monthly_cat_sales
),

peak_season AS (
    -- Step 3: Rank months by revenue within each category
    -- Identifies peak sales periods for each product category
    SELECT
        *,
        RANK() OVER (
            PARTITION BY category_english_name 
            ORDER BY monthly_revenue DESC
        ) AS revenue_rank
    FROM seasonal_cal
)

-- Step 4: Final output with seasonality classification
SELECT 
    category_english_name,
    sales_month,
    monthly_revenue,
    total_unit_sales,
    mom_growth_percent,
    CASE 
        WHEN revenue_rank = 1 THEN 'Peak Season'
        WHEN revenue_rank = 2 THEN 'High Demand'
        WHEN revenue_rank = 3 THEN 'Above Average'
        ELSE 'Normal'
    END AS seasonality_label
FROM peak_season
ORDER BY 
    category_english_name, 
    sales_month;
