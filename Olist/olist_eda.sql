

-- ============================================================
-- Olist E-Commerce — Exploratory Data Analysis Script
-- ============================================================
-- This script performs Exploratory Data Analysis on the data
-- prepared in the companion Olist cleaning script across eight
-- relational tables spanning 99,441 orders, 3,095 sellers, and
-- 32,951 products from Olist, a Brazilian e-commerce platform
-- that connects small and medium-sized merchants to major online
-- marketplaces. The analysis is built to answer one question:
-- where is Olist's marketplace underperforming — and which
-- combination of seller behavior, product category, and delivery
-- patterns drives the highest concentration of late deliveries,
-- low customer satisfaction, and revenue risk? The script moves
-- sequentially from delivery performance analysis through customer
-- satisfaction analysis, revenue and seller performance, and
-- composite risk segmentation — each section building on the prior
-- toward a consolidated finding. All derived columns, segmentation
-- variables, and flag columns referenced throughout this script
-- were created in the companion cleaning script.
--
-- Author: Arohit Talari       
-- Dataset: 8 relational CSV files — Olist Brazilian E-Commerce
-- Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce       
-- MySQL Version: 9.5.0
-- ============================================================


-- ============================================================
-- Section 1: Delivery Performance Analysis
-- ============================================================
-- Section 1 examines delivery performance across the data.
-- Four benchmark numbers are established here and referenced
-- throughout every subsequent section: the overall late delivery
-- rate is 8.11% — 7,826 of 96,478 delivered orders arrived past
-- the estimated delivery date. The average review score across
-- all orders is 4.09. Total revenue generated across the analysis
-- period is $16,008,872.12. Average order value is $160.99.
-- Section 1 examines delivery volume, late delivery concentration,
-- geographic distribution, product category risk, variance
-- distribution, and monthly trend — establishing the operational
-- baseline that Sections 2 through 4 build on.
-- ============================================================

-- 1A. Overall late delivery rate and volume 

-- Establishing the marketplace-level delivery performance baseline.
-- 7,826 of 96,478 delivered orders arrived past the estimated
-- delivery date — an 8.11% late delivery rate. This rate serves
-- as the primary benchmark for every delivery performance
-- comparison in this section and the composite segmentation
-- in Section 4.

SELECT 
	COUNT(*) AS delivered_orders,
    SUM(CASE WHEN is_late_delivery = 1 THEN 1 ELSE 0 END) AS total_late_orders,
	ROUND(AVG(is_late_delivery) * 100,2) AS late_delivery_rate, 
    SUM(CASE WHEN is_late_delivery = 0 THEN 1 ELSE 0 END) AS total_ontime_orders
FROM orders
WHERE order_status = 'delivered'; -- Confirmed: 96,478 delivered orders, 7,826 late, 8.11% late delivery rate, 88,644 on time orders
    
    
-- 1B. Late delivery rate by order status segment 

-- Delivered orders carry the only meaningful late delivery rate
-- at 8.11% across 96,478 orders. All other statuses return NULL
-- — orders that were never shipped, canceled, or still processing
-- have no delivery outcome to measure.

SELECT 
	order_status, 
    COUNT(*) AS order_count,
    ROUND(AVG(is_late_delivery) * 100,2) AS late_delivery_rate
FROM orders
GROUP BY order_status
ORDER BY order_count DESC; 
-- Notable exception: canceled orders show a 16.67% late delivery
-- rate across 625 records. A deeper dive confirmed that a subset
-- of canceled orders carry a populated delivery date — these
-- orders were physically delivered before the cancellation was
-- recorded, likely post-delivery returns or disputes. The late
-- delivery flag is correct for these records — the delivery
-- occurred and was late. Cancellation reflects a subsequent
-- customer action, not a fulfillment failure.


-- 1C. Late delivery rate by customer state

-- Geographic delivery performance from the customer side.
-- Alagoas (AL) leads at 23.93% across 397 orders — nearly triple
-- the 8.11% benchmark. Maranhão (MA) follows at 19.67% across
-- 717 orders. The top five states by late delivery rate —
-- Alagoas (AL), Maranhão (MA), Piauí (PI), Ceará (CE), and
-- Sergipe (SE) — are all in Brazil's Northeast region,
-- geographically distant from São Paulo where 60% of sellers
-- are concentrated. Distance between seller and customer is the
-- likely driver of elevated late delivery rates in these states.
-- States with fewer than 100 delivered orders excluded to prevent
-- unreliable averages from low-volume states.

SELECT 
	c.customer_state,
    COUNT(o.order_id) AS delivered_orders,
	ROUND(AVG(o.is_late_delivery) * 100,2) AS late_delivery_rate
FROM orders o 
JOIN customers c 
ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY customer_state
HAVING COUNT(order_id) > 100
ORDER BY late_delivery_rate DESC;


-- 1D. Late delivery rate by seller state 

-- Geographic delivery performance from the seller side.
-- Maranhão (MA) leads at 23.63% across 402 orders — nearly
-- triple the 8.11% benchmark. São Paulo (SP) dominates by
-- volume at 78,604 orders but delivers at only 8.52% —
-- essentially at the benchmark, reflecting the reliability of
-- Olist's highest volume seller concentration.
--
-- Maranhão (MA) appears in the top two of both 1C and 1D
-- simultaneously — customers in Maranhão (MA) receive late
-- deliveries at 19.67% and sellers in Maranhão (MA) ship late
-- at 23.63%. Maranhão (MA) is a systemic underperformer on
-- both sides of the transaction. States with fewer than 100
-- delivered orders excluded to prevent unreliable averages.

SELECT 
	s.seller_state,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(AVG(o.is_late_delivery) * 100,2) AS late_delivery_rate
FROM order_items oi 
JOIN orders o 
ON oi.order_id = o.order_id 
JOIN sellers s 
ON oi.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_state 
HAVING COUNT(o.order_id) > 100
ORDER BY late_delivery_rate DESC;


-- 1E. Late delivery rate by product category 

-- Audio leads at 12.71% across 362 orders — 57% above the 8.11%
-- benchmark. Fashion underwear and beach follows at 12.60% across
-- 127 orders, christmas_supplies at 12.00% across 150 orders,
-- books_technical at 11.03% across 263 orders, and home_confort
-- at 10.26% across 429 orders. The top five are niche, lower-volume
-- categories with a higher likelihood of freight complexity. Categories
-- with fewer than 100 delivered orders are excluded to prevent
-- unreliable averages. Cross-referenced with freight ratio analysis
-- in Section 4B — high freight burden and high late delivery rate align
-- in most of the same categories, confirming freight complexity
-- as a contributing operational driver.

SELECT
	p.product_category_english,
    COUNT(o.order_id) AS delivered_orders,
    ROUND(AVG(o.is_late_delivery) * 100,2) AS late_delivery_rate
FROM order_items oi 
JOIN orders o 
ON oi.order_id = o.order_id
JOIN products p 
ON oi.product_id = p.product_id
WHERE p.flag_null_category = 0 
AND o.order_status = 'delivered'
GROUP BY p.product_category_english 
HAVING COUNT(o.order_id) > 100
ORDER BY late_delivery_rate DESC; 


-- 1F. Delivery days variance distribution - early vs late breakdown

-- 91.89% of delivered orders arrive before the estimated date —
-- 36.22% by more than 14 days and 55.67% by 1 to 14 days. Only
-- 1.34% arrive exactly on time. 6.77% arrive late — 3.81% by
-- 1 to 7 days, 1.53% by 8 to 14 days, and 1.43% by more than
-- 14 days. 
-- 
-- Olist is not a company with a delivery problem - it is a company
-- with a delivery promise problem. When Olist misses it own 
-- conservative promise, the failures are significant, averaging 8.9 
-- days late. 

SELECT 
	CASE
    WHEN delivery_days_variance < -14 THEN 'Early by more than 14+ days'
    WHEN delivery_days_variance BETWEEN -14 AND -1 THEN 'Early by 1-14 days' 
    WHEN delivery_days_variance = 0 THEN 'On time'
    WHEN delivery_days_variance BETWEEN 1 AND 7 THEN 'Late by 1-7 days'
    WHEN delivery_days_variance BETWEEN 8 AND 14 THEN 'Late by 8-14 days'
    WHEN delivery_days_variance > 14 THEN 'Late by 14+ days'
    END as variance_band,
    COUNT(*) AS order_count, 
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 2) AS pct_of_delivered
FROM orders
WHERE delivery_days_variance IS NOT NULL
GROUP BY variance_band
ORDER BY MIN(delivery_days_variance); 


-- 1G. Monthly order volume and late delivery trend over time 

-- Time series analysis covers January 2017 through August 2018 — 
-- a clean 20-month window. September through December 2016 excluded
-- due to sparse early platform volume that would distort trend interpretation.
--
-- November 2017: 14.31% late delivery rate as order volume surged
-- 63% month over month — plausible Black Friday demand overwhelmed
-- operational capacity.
-- February and March 2018: 15.99% and 21.36% — the worst two
-- consecutive months in the data. Operational anomaly requiring 
-- further investigation. 
-- June 2018: 1.36% — the lowest rate in the 20-month window,
-- suggesting operational recovery following the Q1 2018 crisis.
-- Overall: late delivery rate is volatile and volume-sensitive —
-- Olist's delivery infrastructure has not scaled consistently
-- with platform growth.

SELECT 
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month,
	COUNT(order_id) AS order_volume,
    ROUND(AVG(is_late_delivery) * 100, 2) AS late_delivery_rate
FROM orders
WHERE order_status = 'delivered'
AND order_purchase_timestamp BETWEEN '2017-01-01' AND '2018-08-31'
GROUP BY order_month
ORDER BY order_month ASC;


-- ============================================================
-- Section 2: Customer Satisfaction Analysis
-- ============================================================
-- Section 2 examines how delivery performance translates into
-- customer satisfaction across the data. The two benchmark
-- numbers anchoring this section are the 8.11% late delivery
-- rate from Section 1 and the 4.09 average review score
-- established in the cleaning script. The confirmed 1.72 point
-- review score gap between on-time and late deliveries establishes
-- delivery outcome as the primary driver of customer satisfaction.
-- Section 2 quantifies the satisfaction gap across delivery
-- outcomes, product categories, customer states, and payment
-- types. Findings here feed directly into the composite
-- segmentation in Section 4.
-- ============================================================

-- 2A. Overall review score distribution

-- 77.08% of reviews are 4-star or above — 5-star at 57.78%,
-- 4-star at 19.30%. The distribution is strongly top-heavy,
-- signaling a generally satisfied customer base at the surface
-- level. The 1-star tail at 11.51% across 11,362 reviews is
-- the most actionable dissatisfaction signal in the data —
-- confirmed in block 2B to concentrate among late and
-- undelivered orders where review scores collapse to 2.57
-- and 1.75 respectively.

SELECT
	review_score,
    COUNT(*) AS review_count,
    ROUND(COUNT(review_score) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS pct_of_total
FROM order_reviews
GROUP BY review_score
ORDER BY review_score; 


-- 2B. Average review score by delivery outcome

-- The strongest satisfaction signal in the data. On-time
-- deliveries average 4.29 across 88,168 orders. Late deliveries
-- average 2.57 across 7,662 orders — a confirmed 1.72 point gap
-- on a 5-point scale. Undelivered orders average 1.75 across
-- 2,843 orders — the most severe satisfaction failure, lower
-- even than late deliveries, confirming that customers who never
-- received their order are more dissatisfied than those who
-- received it late. Delivery outcome is the primary driver of
-- customer satisfaction in this data.

SELECT 
	is_late_delivery,
    COUNT(*) AS order_count,
    ROUND(AVG(orv.review_score),2) AS avg_review_score
FROM order_reviews orv
JOIN orders o 
ON orv.order_id = o.order_id
GROUP BY is_late_delivery
ORDER BY is_late_delivery;


-- 2C. Average review score by product category

-- office_furniture carries the lowest satisfaction at 3.49 across
-- 1,677 orders — 0.60 points below the 4.09 benchmark. Large
-- furniture items are notoriously difficult to ship — damage risk
-- and delivery complexity likely drive both late deliveries and
-- satisfaction failures simultaneously. fashion_male_clothing
-- follows at 3.64 across 131 orders, fixed_telephony at 3.68
-- across 261 orders, home_confort at 3.83 across 432 orders,
-- and audio at 3.83 across 360 orders.

SELECT 
	p.product_category_english,
    COUNT(*) AS order_count,
	ROUND(AVG(orv.review_score),2) AS avg_review_score
FROM order_reviews orv 
JOIN order_items oi 
ON orv.order_id = oi.order_id 
JOIN products p 
ON oi.product_id = p.product_id
WHERE flag_null_category = 0
GROUP BY p.product_category_english
HAVING COUNT(*) > 100
ORDER BY avg_review_score; 


-- 2D. Average review score by customer state

-- Alagoas (AL) and Maranhão (MA) both average 3.76 — the lowest
-- satisfaction scores in the data across any state with sufficient
-- volume. Both states appeared in the top two of the 1C late
-- delivery ranking — Alagoas (AL) at 23.93% and Maranhão (MA)
-- at 19.67%. Every state in the 1C top five appears among the
-- eight lowest-satisfaction states in this ranking — geographic
-- delivery failure and satisfaction failure maps are nearly
-- identical, confirming delivery outcome as the primary geographic
-- satisfaction driver. States with fewer than 100 orders excluded
-- to prevent unreliable averages.

SELECT 
	c.customer_state, 
    COUNT(*) AS order_count,
    ROUND(AVG(orv.review_score),2) AS avg_review_score
FROM order_reviews orv
JOIN orders o 
ON orv.order_id = o.order_id 
JOIN customers c 
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
HAVING COUNT(*) > 100
ORDER BY avg_review_score; 


-- 2E. Review score distribution by payment type 

-- Minimal variation across all four payment types — voucher at
-- 4.01, credit_card at 4.09, boleto at 4.09, debit_card at 4.17.
-- The range of 0.16 points confirms payment type is not a
-- satisfaction driver in this data. The finding eliminates payment
-- friction as a contributing factor to dissatisfaction and focuses
-- the analytical conclusion squarely on delivery outcome and
-- product category as the primary satisfaction drivers confirmed
-- in blocks 2B and 2C.

SELECT 
	payment_type,
    COUNT(*) AS order_count,
    ROUND(AVG(orv.review_score),2) AS avg_review_score
FROM order_reviews orv 
JOIN order_payments op 
ON orv.order_id = op.order_id
WHERE op.payment_type IS NOT NULL
GROUP BY op.payment_type
ORDER BY avg_review_score;


-- ============================================================
-- Section 3: Revenue and Seller Performance Analysis
-- ============================================================
-- Section 3 examines where revenue concentrates, which sellers
-- drive the most volume, and how seller performance correlates
-- with delivery reliability and customer satisfaction. Two
-- financial benchmarks anchor this section — total revenue of
-- $16,008,872.12 and average order value of $160.99, both
-- confirmed in Section 1. A minimum of 10 orders is applied
-- to all seller-level analysis throughout this section and
-- Section 4 — the median seller volume is 8 orders, and this
-- threshold removes single-order sellers while retaining a
-- representative portion of the 3,095 seller base. Findings
-- here feed directly into the composite segmentation in
-- Section 4.
-- ============================================================

-- 3A. Total revenue and average order value baseline 

-- Confirming the two financial benchmarks at the EDA script level
-- before any revenue segmentation runs. These two numbers serve
-- as the reference points for every revenue comparison in this
-- section — category revenue, state revenue, and seller revenue
-- are all measured against the marketplace total and average order
-- value confirmed here.

SELECT SUM(order_revenue) AS total_revenue FROM orders; -- Confirmed: 16,008,872.12
SELECT ROUND(AVG(order_revenue),2) AS avg_order_value FROM orders; -- Confirmed: 160.99


-- 3B. Revenue by product category

-- bed_bath_table leads at $1,712,553.67 across 11,115 orders —
-- the highest revenue and highest volume category simultaneously.
-- health_beauty follows at $1,657,373.12, computers_accessories
-- at $1,585,330.45, furniture_decor at $1,430,176.39, and
-- watches_gifts at $1,429,216.68. watches_gifts carries the
-- highest average order value in the top five at $238.56.
-- Three of the top five revenue categories — bed_bath_table,
-- furniture_decor, and computers_accessories — appear in the
-- bottom half of the 2C satisfaction ranking. Olist's highest
-- revenue categories carry above-average satisfaction risk.
-- bed_bath_table presents the clearest commercial risk —
-- highest revenue, highest volume, and a 3.90 average review
-- score below the 4.09 benchmark.

SELECT 
	product_category_english, 
    COUNT(*) AS order_count,
    SUM(order_revenue) AS revenue,
    ROUND(AVG(order_revenue),2) AS avg_order_value
FROM order_items oi
JOIN orders o 
ON oi.order_id = o.order_id 
JOIN products p 
ON oi.product_id = p.product_id
WHERE p.flag_null_category = 0
GROUP BY product_category_english
HAVING COUNT(*) > 100
ORDER BY revenue DESC;


-- 3C. Revenue by customer state

-- São Paulo (SP) leads at $5,998,226.96 across 41,746 orders —
-- 37.5% of total marketplace revenue from a single state.
-- Rio de Janeiro (RJ) follows at $2,144,379.69 and Minas Gerais
-- (MG) at $1,872,257.26. São Paulo (SP), Rio de Janeiro (RJ),
-- and Minas Gerais (MG) combined generate 62.6% of total
-- marketplace revenue — heavy geographic concentration that
-- amplifies the impact of any operational disruption in these
-- three states.
-- Rio de Janeiro (RJ) at 3.88 average review score in 2D
-- represents the most significant revenue at risk — second
-- highest revenue state with below-benchmark customer satisfaction.
-- São Paulo (SP) is the healthiest market — highest revenue,
-- above-benchmark satisfaction at 4.17, and a near-benchmark
-- late delivery rate. States with fewer than 100 orders excluded
-- to prevent unreliable averages.

SELECT 
	c.customer_state,
	COUNT(*) AS order_count, 
    SUM(order_revenue) AS revenue, 
    ROUND(AVG(order_revenue),2) AS avg_order_value
FROM orders o 
JOIN customers c 
ON o.customer_id = c.customer_id 
GROUP BY c.customer_state
HAVING COUNT(*) > 100
ORDER BY revenue DESC;


-- 3D. Top 10 sellers by total revenue 

-- Identifying the highest revenue-generating sellers and their
-- delivery reliability and satisfaction scores simultaneously.
-- The top revenue seller leads at $507,166.91 across 982 orders
-- but carries the lowest review score in the top 10 at 3.34 and
-- a 9.59% late delivery rate above the 8.11% benchmark — the
-- clearest single-seller commercial risk in the data.
-- Four of the top 10 revenue sellers underperform on both delivery
-- and satisfaction simultaneously — $1,406,887.64 in combined
-- revenue carried by sellers failing on both metrics.
-- Seller 53243585 (record 5) is the standout reliable performer — 4.00%
-- late delivery rate at less than half the benchmark with a
-- 4.08 average review score across 358 orders.

SELECT 
	seller_id, 
    total_orders, 
    total_revenue, 
    ROUND(late_delivery_rate * 100,2) AS late_delivery_rate, 
    ROUND(avg_review_score, 2) AS avg_review_score
FROM seller_summary
WHERE total_orders >= 10
ORDER BY total_revenue DESC
LIMIT 10; 


-- 3E. Seller performance distribution 

-- Segmenting the seller base into four performance tiers using
-- the 8.11% late delivery rate and 4.09 average review score
-- as the dividing lines.

-- 492 sellers (38.5%) perform above benchmark on both metrics —
-- the largest single tier, confirming the operational foundation
-- of the seller base is sound. 308 sellers (24.1%) underperform 
-- on both delivery and satisfaction simultaneously — the highest
-- risk tier feeding directly into Section 4 composite segmentation
-- and revenue at risk calculation. 269 sellers deliver on time but
-- generate dissatisfied customers — a non-delivery satisfaction problem
-- not explained by operational metrics alone, suggesting product or
-- listing quality as a contributing factor. 45.4% of active sellers 
-- underperform on at least one metric.

SELECT 
CASE
	WHEN late_delivery_rate IS NULL OR avg_review_score IS NULL THEN 'Insufficient Data'
	WHEN late_delivery_rate <= 0.0811 AND avg_review_score >= 4.09 THEN 'High reliability / High satisfaction'
    WHEN late_delivery_rate <= 0.0811 AND avg_review_score < 4.09 THEN  'High reliability / Low satisfaction'
    WHEN late_delivery_rate > 0.0811 AND avg_review_score >= 4.09 THEN 'Low reliability / High satisfaction'
    ELSE 'Low reliability / Low satisfaction' END AS performance_tier,
    COUNT(*) AS seller_count
FROM seller_summary
WHERE total_orders >= 10
GROUP BY performance_tier; 


-- 3F. High volume vs. low volume seller comparison 

-- High volume sellers (50 or more orders) average 7.78% late
-- delivery rate and 4.06 review score across 429 sellers. Low
-- volume sellers (10 to 49 orders) average 7.98% late delivery
-- rate and 4.08 review score across 842 sellers. The gap of
-- 0.20 percentage points in late delivery rate and 0.02 points
-- in review score is not analytically meaningful — operational
-- scale does not produce measurable performance advantages or
-- disadvantages in this data. Performance variation is driven
-- by individual seller behavior rather than volume tier. 

SELECT 
CASE
	WHEN total_orders >= 50 THEN 'High Volume (50+ orders)'
    WHEN total_orders >= 10 THEN 'Low Volume (10-49 orders)'
END AS volume_tier, 
	COUNT(*) AS seller_count,
    ROUND(AVG(late_delivery_rate) * 100,2) AS late_delivery_rate,
    ROUND(AVG(avg_review_score),2) AS avg_review
FROM seller_summary
WHERE total_orders >= 10
GROUP BY volume_tier
ORDER BY seller_count DESC;


-- ============================================================
-- Section 4: Composite Risk Segmentation
-- ============================================================
-- Section 4 combines the strongest signals from Sections 1 through
-- 3 to identify where late delivery, low satisfaction, and revenue
-- risk concentrate simultaneously. This section directly answers
-- the core analytical question — which combination of seller
-- behavior, product category, and delivery patterns drives the
-- highest concentration of underperformance across the Olist
-- marketplace. The composite segmentation builds on the performance
-- tier framework established in Section 3E and translates
-- operational findings into a financial exposure figure actionable
-- for executive leadership.
-- ============================================================

-- 4A. High risk seller profile 

-- Isolating the Tier 4 seller segment from block 3E — sellers
-- delivering late above the 8.11% benchmark and generating
-- below-benchmark satisfaction simultaneously. 

-- 308 sellers carry $5,562,819.39 in combined revenue — 27.39%
-- of total marketplace revenue flows through sellers delivering
-- late at 16.34% and averaging a 3.65 review score. 16.34% is
-- exactly double the 8.11% benchmark, indicating high risk sellers 
-- are systematically failing, not marginally underperforming.

SELECT 
	COUNT(*) AS high_risk_seller_count,
    SUM(total_revenue) AS combined_revenue,
    ROUND(AVG(late_delivery_rate) * 100,2) AS combined_late_delivery_rate,
    ROUND(AVG(avg_review_score),2) AS combined_avg_review_score
FROM seller_summary
WHERE total_orders >= 10
AND late_delivery_rate > 0.0811
AND avg_review_score < 4.09;


-- 4B. High risk product category profile 

-- Categories where above-benchmark late delivery rate and above-
-- average freight burden concentrate simultaneously represent the
-- highest combined operational and cost risk in the product
-- catalog. The 0.3209 marketplace average freight ratio serves
-- as the freight burden benchmark.

-- christmas_supplies carries the highest freight burden at 0.6755
-- — nearly double the marketplace benchmark — combined with a
-- 12.00% late delivery rate. Seasonal demand concentration drives
-- both cost and operational risk simultaneously.
-- fashion_underwear_beach at 0.5512 freight ratio and 12.60%
-- late delivery rate confirms the pattern — high freight burden
-- and high late delivery rate align with below-benchmark
-- satisfaction from 2C.

SELECT 
	product_category_english,
    COUNT(*) AS order_count,
    ROUND(AVG(is_late_delivery) * 100,2) AS late_delivery_rate,
    ROUND(AVG(freight_ratio),4) AS avg_freight_ratio
FROM order_items oi
JOIN orders o 
ON oi.order_id = o.order_id
JOIN products p 
ON oi.product_id = p.product_id
WHERE flag_null_category = 0
AND o.order_status = 'delivered'
GROUP BY product_category_english
HAVING COUNT(*) >= 100
ORDER BY late_delivery_rate DESC;


-- 4C. Combined risk view — late delivery rate and review score
-- by product category and seller state simultaneously

-- Surfacing which specific category and seller state combinations
-- drive the highest concentration of delivery failure and customer
-- dissatisfaction simultaneously.

-- bed_bath_table from Paraná (PR) sellers leads at 22.73% late
-- delivery rate and 3.42 average review score — the worst
-- simultaneous delivery and satisfaction performance in the data
-- while being the highest revenue and highest volume category.
-- health_beauty from Maranhão (MA) sellers at 22.53% confirms
-- that the Maranhão (MA) seller state risk identified in 1D
-- extends into the second highest revenue category.

SELECT 
	p.product_category_english,
    s.seller_state,
    ROUND(AVG(o.is_late_delivery) * 100,2) AS avg_late_delivery_rate,
    ROUND(AVG(orv.review_score),2) AS avg_review_score
FROM order_items oi 
JOIN orders o 
ON oi.order_id = o.order_id
JOIN products p 
ON oi.product_id = p.product_id
JOIN sellers s
ON oi.seller_id = s.seller_id
JOIN order_reviews orv
ON oi.order_id = orv.order_id
WHERE p.flag_null_category = 0
AND o.order_status = 'delivered'
GROUP BY p.product_category_english, s.seller_state
HAVING COUNT(*) > 100
ORDER BY avg_late_delivery_rate DESC;


-- 4D. Revenue at risk

-- $5,562,819.39 — 27.39% of total marketplace revenue — flows
-- through the 308 Tier 4 sellers (Low reliability/Low satisfaction)
-- identified in Section 4A. More than one quarter of Olist's marketplace
-- revenue is carried by sellers simultaneously delivering late at double
-- the benchmark rate and generating below-benchmark customer satisfaction.
-- This is the most consequential finding within the EDA, which translates 
-- where operational underperformance occurs and as a result, the revenue at
-- risk.

SELECT
	SUM(total_revenue) AS revenue_at_risk,
	COUNT(*) AS seller_count,
    ROUND(SUM(total_revenue) * 100.0 / (SELECT SUM(total_revenue) FROM seller_summary),2) AS pct_of_portfolio
FROM seller_summary
WHERE total_orders >= 10
AND late_delivery_rate > 0.0811 
AND avg_review_score < 4.09;


-- ============================================================
-- Section 5: Summary Findings
-- ============================================================
-- Section 5 consolidates the most analytically significant findings
-- from Sections 1 through 4 into a set of actionable conclusions
-- tailored for Olist's executives, so they can better understand
-- where the company's marketplace is underperforming and which
-- combination of seller behavior, product category, and delivery
-- patterns drives the highest concentration of late deliveries,
-- low customer satisfaction, and revenue risk. This section
-- contains no queries — findings are presented as analytical
-- conclusions drawn from the evidence produced across
-- Sections 1 through 4.
-- 
-- Finding 1: Olist's delivery promise is systematically conservative but
-- operationally fragile
-- 91.89% of orders arrive early — 36.22% by more than 14 days. The 8.11% 
-- late delivery rate sits against a backdrop of systematic over-estimation. 
-- When Olist misses its own conservative promise the failures are significant
-- — averaging 8.9 days late with a maximum of 188 days.
-- 
-- Finding 2: Delivery outcome is the primary driver of customer satisfaction
-- On-time deliveries average 4.29 review score across 88,168 orders. Late 
-- deliveries average 2.57 across 7,662 orders — a 1.72 point gap on a 5-point 
-- scale. Undelivered orders average 1.75 across 2,843 orders — the most severe
-- satisfaction failure in the data.
-- 
-- Finding 3: November 2017 and Q1 2018 represent the two most severe operational
-- failures 
-- November 2017 late delivery rate spiked to 14.31% as order volume surged 63% 
-- month over month — Black Friday demand overwhelmed operational capacity. 
-- February and March 2018 reached 15.99% and 21.36% respectively — the worst two
-- consecutive months in the data. Volume alone does not explain Q1 2018 — an 
-- unresolved operational anomaly requiring further investigation.
--
-- Finding 4: Maranhão (MA) underperforms on both sides of the transaction simultaneously
-- Maranhão (MA) customers receive late deliveries at 19.67% —
-- second highest customer state in the data. Maranhão (MA)
-- sellers ship late at 23.63% — the highest seller state.
-- Maranhão (MA) customers average 3.76 review score — joint
-- lowest in the data alongside Alagoas (AL). Maranhão (MA) is
-- the only state appearing in the top two of both the delivery
-- failure and satisfaction failure rankings simultaneously.
--
-- Finding 5: products categorized under bed_bath_table is the highest commercial risk category 
-- Highest revenue category at $1,712,553.67 across 11,115 orders.
-- Below-benchmark satisfaction at 3.90 average review score. Worst
-- composite delivery and satisfaction performance at the category-state
-- level — bed_bath_table from Paraná (PR) sellers at 22.73% late 
-- delivery rate and 3.42 average review score. The combination of highest
-- revenue concentration and worst composite operational performance makes
-- this the single most actionable category finding.
--
-- Finding 6: 27.39% of marketplace revenue flows through the
-- highest risk seller segment
-- 308 sellers carrying $5,562,819.39 in combined revenue
-- simultaneously deliver late at 16.34% — double the 8.11%
-- benchmark — and generate a 3.65 average review score against
-- the 4.09 marketplace benchmark. More than one quarter of
-- Olist's marketplace revenue is carried by sellers
-- underperforming on both operational and satisfaction metrics
-- simultaneously.
--
-- Finding 7: Freight burden and late delivery risk concentrate
-- in the same categories
-- christmas_supplies carries the highest freight burden at 0.6755
-- freight ratio — nearly double the 0.3209 marketplace benchmark
-- — combined with a 12.00% late delivery rate.
-- fashion_underwear_beach at 0.5512 freight ratio and 12.60%
-- late delivery rate confirms the pattern. Seasonal and low-value
-- categories where freight costs approach or exceed product price
-- are the most operationally and financially exposed segments in
-- the product catalog.
-- ============================================================
