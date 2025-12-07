/*
PART-TO-WHOLE ANALYSIS
Objective: Measure relative contribution of segments to overall performance
Purpose: Identify key revenue drivers at category and regional levels
Expected Outcome: Two separate analyses showing market share distributions
Business Use: Resource allocation, strategic focus, and performance benchmarking
*/

-- ANALYSIS 1: CATEGORY SHARE OF TOTAL REVENUE
-- Determines which product categories drive the most revenue
WITH category_revenue AS (
    -- Calculate total revenue for each product category
    SELECT
        p.category_english_name,
        SUM(oi.total_order_cost) as revenue_by_category
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_products p   
        ON p.product_custome_key = oi.product_custome_key
    GROUP BY p.category_english_name
),

total_revenue AS (
    -- Calculate overall platform revenue for denominator
    SELECT SUM(revenue_by_category) as overall_revenue
    FROM category_revenue
),

category_market_share AS (
    -- Compute each category's percentage of total revenue
    SELECT
        cr.category_english_name,
        cr.revenue_by_category,
        CAST((cr.revenue_by_category * 100 / tr.overall_revenue) as DECIMAL(10,2)) as market_share 
    FROM category_revenue cr    
    CROSS JOIN total_revenue tr  -- Single value join for calculation
)

-- Final output: Categories ranked by revenue contribution
SELECT
    category_english_name,
    revenue_by_category,
    CONCAT(market_share,'%') as category_market_share
FROM category_market_share
ORDER BY market_share DESC;



-- ANALYSIS 2: REGIONAL SHARE OF SELLER REVENUE
-- Identifies which geographic regions contribute most to seller revenue
WITH seller_revenue AS (
    -- Calculate total revenue for each individual seller with location data
    SELECT 
        s.seller_custome_key,
        s.seller_city,
        s.seller_state,
        SUM(oi.total_order_cost) as seller_overall_revenue
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_sellers s  
        ON oi.seller_custome_key = s.seller_custome_key
    GROUP BY  s.seller_custome_key,
              s.seller_city,
              s.seller_state
),

region_revenue AS (
    -- Aggregate revenue to city-state level (regional granularity)
    SELECT 
        seller_city,
        seller_state,
        SUM(seller_overall_revenue) as revenue_by_region
    FROM seller_revenue
    GROUP BY seller_city,
             seller_state
),

total_revenue AS (
    -- Calculate total platform revenue (different scope from Analysis 1)
    SELECT
        SUM(revenue_by_region) as total_overll_revenue
    FROM region_revenue
),

region_market_share AS (
    -- Compute market share percentage for each city-state combination
    SELECT 
        seller_city,
        seller_state,
        CAST((revenue_by_region * 100)/tr.total_overll_revenue as decimal(10,2)) as market_share
    FROM region_revenue rr  
    CROSS JOIN total_revenue tr
),

city_market_share AS (
    -- Intermediate step for city-level market share (pre-state aggregation)
    SELECT
        seller_state,
        seller_city,
        market_share 
    FROM region_market_share
)

-- Final output: States ranked by total revenue contribution
SELECT
    seller_state,
    CAST(SUM(market_share) as nvarchar) +'%' as state_market_share
FROM region_market_share
GROUP BY seller_state
ORDER BY state_market_share DESC;