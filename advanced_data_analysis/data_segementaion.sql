/*
DATA SEGMENTATION - MARKET BASKET ANALYSIS
Objective: Find product categories purchased together in the same order
Purpose: Build category-to-category affinity matrix for bundle opportunities
Expected Outcome: Category pairs with co-purchase frequency and affinity scores
Business Use: Cross-selling strategies, bundle recommendations, and merchandising optimization
*/

WITH order_category AS (
    -- EXTRACT ORDER-CATEGORY RELATIONSHIPS: Map each order to its product categories
    -- Foundation for identifying which categories appear together in transactions
    SELECT
        oi.order_custome_id,
        p.category_english_name
    FROM gold_BE.fact_order_items oi  
    LEFT JOIN gold_BE.dim_products p  
        ON p.product_custome_key = oi.product_custome_key
),

category_pairs AS (
    -- GENERATE CATEGORY PAIRS: Create unique category combinations within each order
    -- Uses self-join with inequality to avoid duplicates (A,B) vs (B,A) and self-pairs
    SELECT
        a.order_custome_id,
        a.category_english_name as category_a,
        b.category_english_name as category_b
    FROM order_category a 
    LEFT JOIN order_category b  
        ON a.order_custome_id = b.order_custome_id
        AND a.category_english_name < b.category_english_name
),

pair_counts AS (
    -- COUNT PAIR FREQUENCY: Aggregate how often each category pair appears together
    -- Raw co-occurrence count without normalization
    SELECT 
        category_a,
        category_b,
        COUNT(*) as pair_count 
    FROM category_pairs
    GROUP BY category_a,
             category_b
),

category_counts AS (
    -- CALCULATE CATEGORY POPULARITY: Total occurrences of each category
    -- Baseline for understanding individual category performance
    SELECT 
        category_english_name,
        COUNT(*) as total_occurrences
    FROM order_category
    GROUP BY category_english_name
),

affinity_matrix AS (
    -- COMPUTE AFFINITY SCORES: Normalize pair frequency by category popularity
    -- Formula: pair_count / min(total_occurrences_A, total_occurrences_B)
    -- Measures how strongly categories are associated beyond individual popularity
    SELECT 
        p.category_a,
        p.category_b,
        p.pair_count,

        ca.total_occurrences AS total_a,
        cb.total_occurrences AS total_b,

        ROUND(
            p.pair_count * 1.0 
            / NULLIF(LEAST(ca.total_occurrences, cb.total_occurrences), 0), 
        3) AS affinity_score
    FROM pair_counts p
    LEFT JOIN category_counts ca 
        ON p.category_a = ca.category_english_name
    LEFT JOIN category_counts cb 
        ON p.category_b = cb.category_english_name
)

-- FINAL OUTPUT: Category affinity pairs ranked by association strength
SELECT 
    category_a,
    category_b,
    pair_count,
    CAST(affinity_score as DECIMAL(10,2)) as affinity_score
FROM affinity_matrix
WHERE affinity_score IS NOT NULL
ORDER BY affinity_score DESC, pair_count DESC;