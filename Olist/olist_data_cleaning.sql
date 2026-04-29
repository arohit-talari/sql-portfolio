

-- ============================================================
-- Olist E-Commerce — Data Cleaning & Transformation Script
-- ============================================================
-- Olist is a Brazilian e-commerce platform that connects small and
-- medium-sized merchants to major online marketplaces, enabling them
-- to reach a broader customer base without managing their own
-- storefront infrastructure or logistics. The core analytical
-- question driving this project is: where is Olist's marketplace
-- underperforming — and which combination of seller behavior,
-- product category, and delivery patterns drives the highest
-- concentration of late deliveries, low customer satisfaction,
-- and revenue risk? This script covers data cleaning and
-- transformation only across eight relational tables. The companion
-- EDA script applies the cleaned data to answer the core
-- analytical question.
--
-- Author: Arohit Talari
-- Dataset: 8 relational CSV files — Olist Brazilian E-Commerce
-- Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
-- MySQL Version: 9.5.0
-- ============================================================


-- ============================================================
-- TABLE 1: customers
-- No dependencies — load first
-- ============================================================
CREATE TABLE customers (
    customer_id             VARCHAR(50)     NOT NULL, -- Primary key, uniquely identifies each order-level customer record
    customer_unique_id      VARCHAR(50)     NOT NULL, -- True repeat-customer identifier - the same physical customer gets a different customer_id for each order they place
    customer_state          VARCHAR(2)      NOT NULL, -- Two-character Brazilian state code - used for geographic delivery performance segmentation in EDA script
    PRIMARY KEY (customer_id)
);

-- ============================================================
-- TABLE 2: sellers
-- No dependencies — load second
-- ============================================================
CREATE TABLE sellers (
    seller_id               VARCHAR(50)     NOT NULL, -- Primary key, join key to order_items table 
    seller_city             VARCHAR(100)    NOT NULL, -- Seller city - Sao Paulo dominantes with 1,849 of 3,095 sellers (59.7% of seller base) 
    seller_state            VARCHAR(2)      NOT NULL, -- Two-character Brazilian state code - used for geographic seller concentration analysis in the EDA script
    PRIMARY KEY (seller_id)
);

-- ============================================================
-- TABLE 3: products
-- No dependencies — load third
-- product_name_lenght and product_description_lenght are
-- intentional source typos — corrected at table definition
-- ============================================================
CREATE TABLE products (
    product_id                  VARCHAR(50)     NOT NULL, -- Primary key, join key to order_items 
    product_category_name       VARCHAR(100)    NULL, -- Product category stored in Portuguese. Nullable - 610 products carry no category. Translated to English in Section 4G via JOIN to product_category table. Two product categories have no English translation (pc_gamer, portateis_cozinha_e_preparadores_de_alimentos) 
    product_weight_g            DECIMAL(10,2)   NULL, -- Stored as a DECIMAL rather than INT due to source data carrying decimal precision on weight values. Nullable - 6 products carry no weight following zero to NULL conversion in 2C
    product_length_cm           DECIMAL(10,2)   NULL, -- DECIMAL, nullable - 2 products carry no measurements, converted from zero in Section 2D
    product_height_cm           DECIMAL(10,2)   NULL, -- DECIMAL, nullable - 2 products carry no measurements, converted from zero in Section 2D
    PRIMARY KEY (product_id)
);

-- ============================================================
-- TABLE 4: product_category
-- No dependencies — load fourth
-- Lookup table translating Portuguese category names to English
-- Both columns serve as join keys — neither is nullable
-- ============================================================
CREATE TABLE product_category (
    product_category_name           VARCHAR(100)    NOT NULL, -- Primary key, Portuguese category name, join key to products table
    product_category_name_english   VARCHAR(100)    NOT NULL, -- English translation of product category name - 71 categories translated. Two categories present in the products table have no translation - addressed in Section 2
    PRIMARY KEY (product_category_name)
);

-- ============================================================
-- TABLE 5: orders
-- Depends on customers
-- All timestamp columns stored as VARCHAR in source —
-- converted to DATETIME in Section 4
-- Nullable timestamps reflect orders not yet approved,
-- shipped, or delivered — structurally valid
-- ============================================================
CREATE TABLE orders (
    order_id                        VARCHAR(50)     NOT NULL, -- Primary key, central join key connecting every other table in the schema
    customer_id                     VARCHAR(50)     NOT NULL, -- Foreign key to customers table 
    order_status                    VARCHAR(20)     NOT NULL, -- 8 distinct values. 96,478 delivered orders 
    -- All five timestamp columns loaded as VARCHAR and converted to DATETIME in Section 4A - MySQL cannot reliably parse timestamp strings at load time
    order_purchase_timestamp        VARCHAR(30)     NOT NULL, 
    order_approved_at               VARCHAR(30)     NULL,  -- Nullable - 160 nulls - orders never approved
    order_delivered_carrier_date    VARCHAR(30)     NULL, -- Nullable - 1,783 nulls - orders never picked up by carrier
    order_delivered_customer_date   VARCHAR(30)     NULL, -- Nullable - 2,965 nulls - orders never delivered
    order_estimated_delivery_date   VARCHAR(30)     NOT NULL, -- NOT NULL - every order receives an estimated delivery date at placement
    PRIMARY KEY (order_id)
);

-- ============================================================
-- TABLE 6: order_items
-- Depends on orders, products, sellers
-- ============================================================
CREATE TABLE order_items (
    order_id                VARCHAR(50)     NOT NULL, -- Composite join key connected to orders table
    order_item_id           TINYINT         NOT NULL, -- Integer identifying individual items within a multi-item order. Most orders contain one item - median is 1, maximum is 21
    product_id              VARCHAR(50)     NOT NULL, -- Composite join key connected to products table
    seller_id               VARCHAR(50)     NOT NULL, -- Composite join key connected to sellers table
    shipping_limit_date     VARCHAR(30)     NOT NULL, -- Loaded as VARCHAR, converted to DATETIME in Section 4B. Represents the deadline by which seller must ship the item 
    price                   DECIMAL(10,2)   NOT NULL, -- Loaded as DECIMAL due to financial precision
    freight_value           DECIMAL(10,2)   NOT NULL -- Loaded as DECIMAL due to financial precision. Freight averages 32.1% of product price across the data - examined further as a significant cost burden in the EDA script
);

-- ============================================================
-- TABLE 7: order_payments
-- Depends on orders
-- ============================================================
CREATE TABLE order_payments (
    order_id                VARCHAR(50)     NOT NULL, -- Join key to orders. 2,246 orders have multiple payment records - a customer may split payment across credit card and voucher, for example. Aggregate payment_value by order_id in EDA
    payment_type            VARCHAR(20)     NOT NULL, -- Five payment type values - four valid, one invalid. 3 records carry 'not_defined' - an invalid encoding resolved in Section 2A
    payment_installments    TINYINT         NOT NULL, -- Loaded as a TINYINT due to installment counts ranging from 1 - 24
    payment_value           DECIMAL(10,2)   NOT NULL -- Loaded as a DECIMAL due to financial precision
);

-- ============================================================
-- TABLE 8: order_reviews
-- Depends on orders
-- review_creation_date stored as VARCHAR — converted in Section 4
-- 547 orders carry multiple reviews — resolved in Section 2F
-- ============================================================
CREATE TABLE order_reviews (
    order_id                VARCHAR(50)     NOT NULL, -- Join key to orders. 547 orders carry multiple review records - deduplication strategy keeping most recent review per order applied in Section 2E
    review_score            TINYINT         NOT NULL, -- Loaded as a TINYINT due to review scores ranging from 1 - 5, average being 4.09. Relationship between delivery performance and review score is the strongest analytical signal in the data - on-time deliveries average 4.29 vs. 2.57 for late deliveries
    review_creation_date    VARCHAR(30)     NOT NULL -- Loaded as a VARCHAR, converted to DATETIME in Section 4C
);


-- ============================================================
-- LOAD DATA
-- ============================================================
-- Eight tables with relational dependencies require a deliberate
-- load sequence. Tables with no dependencies load first — customers,
-- sellers, products, and product_category. Tables that depend on
-- others load after their dependencies exist — orders after customers,
-- order_items after orders, products, and sellers, and order_payments
-- and order_reviews after orders. Foreign key constraints were not
-- enforced at the database level but the load sequence respects the
-- relational structure intentionally.
--
-- Four intentional decisions were made during load:
-- FIELDS TERMINATED BY ',' — CSV files use commas as the field
-- delimiter, confirmed against the source files.
-- OPTIONALLY ENCLOSED BY '"' — string fields containing commas
-- within their values would be misread as field delimiters without
-- this instruction, ensuring MySQL treats anything inside double
-- quotes as a single field value regardless of internal commas.
-- IGNORE 1 ROWS — the first row of every CSV is a header row
-- containing column names, not data. Without this instruction MySQL
-- would attempt to load the header as a data record and either throw
-- a type mismatch error or insert a corrupt first row.
-- LINES TERMINATED BY '\n' — matches how these CSVs terminate lines.
-- Without it MySQL may misread row boundaries or carry invisible
-- characters into field values.
-- ============================================================


-- ============================================================
-- Baseline State
-- ============================================================
-- Prior to any cleaning or transformation, surfacing the baseline
-- state of all eight tables.
--
-- Row counts confirmed:
-- customers:        99,441
-- sellers:           3,095
-- products:         32,951
-- product_category:     71
-- orders:           99,441
-- order_items:     112,650
-- order_payments:  103,886
-- order_reviews:    99,224
--
-- Known data quality issues identified prior to cleaning:
-- products:       610 null category names
--                 6 zero weight records — physically implausible
--                 2 null dimension records
-- orders:         160 empty approved timestamps
--                 1,783 empty carrier timestamps
--                 2,965 empty delivered timestamps
-- order_payments: 3 records carrying invalid payment type
--                 'not_defined'
-- order_reviews:  547 orders carrying duplicate review records
--
-- customers, sellers, product_category, and order_items
-- loaded clean with no known data quality issues.
-- ============================================================


-- ============================================================
-- Section 1: Initial Data Profiling and Baseline Audit
-- ============================================================
-- Section 1 produces no changes to the data. It is observation only.
-- Every query in this section is a SELECT — nothing is updated,
-- deleted, or inserted. The purpose is to establish what the data
-- actually contains before any cleaning decisions are made in
-- Sections 2 through 6. The overall late delivery rate and average
-- review score confirmed here serve as the primary benchmarks for
-- every operational and satisfaction comparison in the EDA script.
-- ============================================================

-- 1A. Row count confirmation across all eight tables
SELECT 'customers' AS table_name, COUNT(*) AS records FROM customers
UNION ALL 
SELECT 'order_items' AS table_name, COUNT(*) AS records FROM order_items
UNION ALL 
SELECT 'order_payments' AS table_name, COUNT(*) AS records FROM order_payments
UNION ALL 
SELECT 'order_reviews' AS table_name, COUNT(*) AS records FROM order_reviews
UNION ALL 
SELECT 'orders' AS table_name, COUNT(*) AS records FROM orders
UNION ALL 
SELECT 'product_category' AS table_name, COUNT(*) AS records FROM product_category
UNION ALL 
SELECT 'products' AS table_name, COUNT(*) AS records FROM products
UNION ALL 
SELECT 'sellers' AS table_name, COUNT(*) AS records FROM sellers; 
-- Expected: customers 99,441 — sellers 3,095 — products 32,951
-- product_category 71 — orders 99,441 — order_items 112,650
-- order_payments 103,886 — order_reviews 99,224


-- 1B. NULL and empty string audit

-- Products: null, zero, and blank value checks
SELECT COUNT(*) AS blank_category
FROM products 
WHERE product_category_name = ''; -- 610 blank category names

SELECT COUNT(*) AS zero_weight
FROM products 
WHERE product_weight_g = 0; -- 6 zero weight records

SELECT COUNT(*) AS zero_dimensions
FROM products 
WHERE product_length_cm = 0; -- 2 zero dimension records

-- Orders: empty timestamp checks
SELECT
	SUM(CASE WHEN order_approved_at = '' THEN 1 ELSE 0 END) AS empty_approved, -- Expected: 160
    SUM(CASE WHEN order_delivered_carrier_date = '' THEN 1 ELSE 0 END) AS empty_carrier, -- Expected: 1783
    SUM(CASE WHEN order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS empty_delivered -- Expected: 2965
FROM orders; 

-- Order payments: invalid payment type
SELECT COUNT(*) AS not_defined
FROM order_payments 
WHERE payment_type = 'not_defined'; -- 3 records carrying invalid payment type 'not_defined'

-- Order reviews: duplicate order check
SELECT 
	order_id, COUNT(order_id) 
FROM order_reviews 
GROUP BY order_id 
HAVING COUNT(order_id) > 1; -- Expected: 547


-- 1C. Distinct value checks on categorical columns

-- Order status distribution
SELECT order_status, COUNT(*) AS distribution 
FROM orders 
GROUP BY order_status
ORDER BY distribution DESC; -- 8 distinct values, delivered orders make up 97% of the distribution

-- Payment type distribution 
SELECT payment_type, COUNT(*) AS distribution 
FROM order_payments
GROUP BY payment_type
ORDER BY distribution DESC; -- 5 distinct values, orders paid by credit_card make up 74% of the distribution. 3 'not_defined' records resolved in 2A

-- Customer state distribution
SELECT customer_state, COUNT(*) AS distribution  
FROM customers
GROUP BY customer_state
ORDER BY distribution DESC; -- 27 distinct values, SP (Sao Paulo) makes up 42% of the customer distribution

-- Seller state distribution
SELECT DISTINCT(seller_state), COUNT(*) AS distribution 
FROM sellers
GROUP BY seller_state; -- 23 distinct values, SP (Sao Paulo) makes up 60% of the seller distribution
-- Seller geographic concentration examined in EDA alongside customer distribution 

-- Product category distribution
SELECT DISTINCT(product_category_name), COUNT(*) AS distribution
FROM products
GROUP BY product_category_name
ORDER BY distribution DESC; -- 74 distinct values, including NULL. cama_mesa_banho makes up 9% of the product category distribution
-- Category name is stored in Portuguese - translated to English in Section 4G via JOIN to product_category table


-- 1D. Date Format Verification 

-- Confirming timestamp format across all three tables containing
-- date columns before conversion to DATETIME in Section 4.

-- orders: five timestamp columns
SELECT 
	order_purchase_timestamp, 
    order_approved_at, 
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
LIMIT 5; -- All five columns confirmed in YYYY-MM-DD HH:MM:SS format 
-- Nullable columns show NULL or empty string where orders were not approved, shipped, or delivered

-- order_items: one timestamp column
SELECT 
	shipping_limit_date
FROM order_items
LIMIT 5; -- Single timestamp column confirmed in YYYY-MM-DD HH:MM:SS format 

-- order_reviews: one timestamp column
SELECT 
	review_creation_date
FROM order_reviews
LIMIT 5; -- Single timestamp column confirmed in YYYY-MM-DD HH:MM:SS format 


-- 1E. Duplicate Review Check 
SELECT order_id, COUNT(order_id) AS duplicates
FROM order_reviews 
GROUP BY order_id
HAVING duplicates > 1; 
-- 547 duplicates orders confirmed -- each carries more than one review record. 
-- Deduplication strategy keeping the most recent review per order_id applied in Section 2E


-- 1F. Referential integrity checks 

-- Confirming each JOIN relationship (6) returns the expected record count

-- orders to customers
SELECT COUNT(*) AS orders_matched_to_customers
FROM orders o 
JOIN customers c 
ON o.customer_id = c.customer_id; -- Expected: 99,441 - matches full orders table

-- order_items to orders
SELECT COUNT(*) AS items_matched_to_orders
FROM order_items oi 
JOIN orders o 
ON oi.order_id = o.order_id; -- Expected: 112,650 - matches full order_items table 

-- order_items to products
SELECT COUNT(*) AS items_matched_to_products 
FROM order_items oi 
JOIN products p 
ON oi.product_id = p.product_id; -- Expected: 112,650 - matches full order_items table 

-- order_items to sellers
SELECT COUNT(*) AS items_matched_to_sellers
FROM order_items oi 
JOIN sellers s 
ON oi.seller_id = s.seller_id; -- Expected: 112,650 - matches full order_items table

-- order_reviews to orders 
SELECT COUNT(*) AS reviews_matched_to_orders
FROM order_reviews ors
JOIN orders o 
ON ors.order_id = o.order_id; -- Expected: 99,224 - matches full order_reviews table 

-- order_payments to orders 
SELECT COUNT(*) AS payments_matched_to_orders
FROM order_payments os 
JOIN orders o 
ON os.order_id = o.order_id; -- Expected: 103,886 - matches full order_payments table


-- 1G. Delivery performance baseline 

-- Delivered order count
SELECT order_status, COUNT(order_status) AS delivered_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY order_status; -- 96,478 of 99,441 orders have been marked as 'delivered'

-- Note: late delivery rate, average days late, and maximum days late
-- require DATETIME comparisons and cannot be calculated until timestamp
-- columns are converted in Section 4.


-- 1H. Review score and revenue baseline 

-- Average review score across all orders
SELECT ROUND(AVG(review_score),2) AS avg_review_score
FROM order_reviews; -- Average review score = 4.09 - benchmark for every satisfaction comparison in EDA

SELECT ROUND(SUM(payment_value),2) AS total_revenue
FROM order_payments; -- Total revenue = $16,008,872.12 - total payment value across all orders

SELECT ROUND(AVG(order_total),2) AS avg_order_value
FROM (
	SELECT order_id, SUM(payment_value) AS order_total
    FROM order_payments 
    GROUP BY order_id) AS order_totals; -- Average order value = $160.99 per order
    

-- ============================================================
-- Section 2: Incorrect and Invalid Value Correction
-- ============================================================
-- Section 2 resolves incorrect and invalid values before any missing
-- value handling occurs. Incorrect values must be addressed first
-- because conflating them with missing values risks replacing bad
-- data with statistically derived values that appear legitimate but
-- are not. Resolving invalid encodings first ensures Section 3 is
-- working with a clean foundation across all eight tables.
-- ============================================================

-- 2A. order_payments: not_defined → NULL

-- 'not_defined' is not a valid payment type. 3 records carry this
-- encoding. Setting to NULL before any payment type segmentation.

-- Before count: confirm 3 records carry not_defined
SELECT COUNT(*) AS before_count
FROM order_payments
WHERE payment_type = 'not_defined'; -- Expected: 3

-- Modify payment_type to allow NULL values
-- Column was defined NOT NULL at table creation — 
-- made nullable so NULL value can be inserted 
ALTER TABLE order_payments
MODIFY payment_type VARCHAR(20) NULL;

-- Apply correction
UPDATE order_payments
SET payment_type = NULL
WHERE payment_type = 'not_defined';

-- After count: confirm 0 records carry not_defined
SELECT COUNT(*) AS after_count
FROM order_payments
WHERE payment_type = 'not_defined'; -- Expected: 0


-- 2B. products: blank category names → NULL

-- 610 records carry an empty string under product_category_name
-- rather than NULL. Empty strings must be converted to
-- NULL before Section 3 flagging logic runs — Section 3A will
-- flag these records as uncategorized rather than impute a category.

-- Before count: confirm 610 records carry empty category name
SELECT COUNT(*) AS before_count
FROM products
WHERE product_category_name = ''; -- Expected: 610

-- Apply correction
UPDATE products
SET product_category_name = NULL
WHERE product_category_name = '';

-- After count: confirm 610 NULLs now present
SELECT COUNT(*) AS after_count
FROM products
WHERE product_category_name IS NULL; -- Expected: 610


-- 2C. products: zero weight → NULL

-- 6 records carry a weight of 0.00 — implausible for
-- any shipped product. Zero weight is not a valid —
-- it indicates missing data encoded as zero rather than NULL.
-- Converting to NULL before Section 3B flagging logic runs.

-- Before count: confirm 6 records carry zero weight
SELECT COUNT(*) AS before_count
FROM products
WHERE product_weight_g = 0; -- Expected: 6

-- Apply correction
UPDATE products
SET product_weight_g = NULL
WHERE product_weight_g = 0;

-- After count: confirm 0 zero weight records remain
SELECT COUNT(*) AS after_count_zero
FROM products
WHERE product_weight_g = 0; -- Expected: 0

-- Confirm 6 NULLs now present
SELECT COUNT(*) AS null_weight_count
FROM products
WHERE product_weight_g IS NULL; -- Expected: 6


-- 2D. products: zero dimensions → NULL

-- 2 records carry zero values in product_length_cm and
-- product_height_cm — implausible for any shipped product.
-- Zero dimensions indicate missing data encoded as zero
-- rather than NULL. Converting to NULL before Section 3C
-- documents these as structurally missing product data.

-- Before count: confirm zero dimension records
SELECT COUNT(*) AS before_count_length
FROM products
WHERE product_length_cm = 0; -- Expected: 2

SELECT COUNT(*) AS before_count_height
FROM products
WHERE product_height_cm = 0; -- Expected: 2

-- Apply correction to length
UPDATE products
SET product_length_cm = NULL
WHERE product_length_cm = 0;

-- Apply correction to height
UPDATE products
SET product_height_cm = NULL
WHERE product_height_cm = 0;

-- After count: confirm 0 zero dimension records remain
SELECT COUNT(*) AS after_count_length
FROM products
WHERE product_length_cm = 0; -- Expected: 0

SELECT COUNT(*) AS after_count_height
FROM products
WHERE product_height_cm = 0; -- Expected: 0

-- Confirm 2 NULLs now present in each dimension column
SELECT COUNT(*) AS null_length_count
FROM products
WHERE product_length_cm IS NULL; -- Expected: 2

SELECT COUNT(*) AS null_height_count
FROM products
WHERE product_height_cm IS NULL; -- Expected: 2


-- 2E. orders: empty timestamp strings → NULL

-- Three timestamp columns loaded empty strings rather than NULL
-- for orders that were never approved, never picked up by a carrier,
-- or never delivered. Empty strings must be converted to proper NULL
-- before Section 4A date conversion runs.

-- Before counts: confirm expected empty string counts
SELECT COUNT(*) AS before_approved
FROM orders
WHERE order_approved_at = ''; -- Expected: 160

SELECT COUNT(*) AS before_carrier
FROM orders
WHERE order_delivered_carrier_date = ''; -- Expected: 1,783

SELECT COUNT(*) AS before_delivered
FROM orders
WHERE order_delivered_customer_date = ''; -- Expected: 2,965

-- Apply corrections
UPDATE orders
SET order_approved_at = NULL
WHERE order_approved_at = '';

UPDATE orders
SET order_delivered_carrier_date = NULL
WHERE order_delivered_carrier_date = '';

UPDATE orders
SET order_delivered_customer_date = NULL
WHERE order_delivered_customer_date = '';

-- After counts: confirm 0 empty strings remain
SELECT COUNT(*) AS after_approved
FROM orders
WHERE order_approved_at = ''; -- Expected: 0

SELECT COUNT(*) AS after_carrier
FROM orders
WHERE order_delivered_carrier_date = ''; -- Expected: 0

SELECT COUNT(*) AS after_delivered
FROM orders
WHERE order_delivered_customer_date = ''; -- Expected: 0

-- Confirm NULLs now present
SELECT
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved, -- Expected: 160
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier, -- Expected: 1,783
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered -- Expected: 2,965
FROM orders;


-- 2F. order_reviews: deduplicate — keep most recent review per order

-- 547 orders carry multiple review records. Strategy: keep the review
-- with the most recent review_creation_date per order_id and delete
-- all older duplicates. This ensures one review per order enters
-- the EDA script without losing the most analytically relevant
-- customer feedback.

-- Step 1: Create temporary table with one record per order_id
-- Where dates tie, the higher review_score is kept
CREATE TEMPORARY TABLE order_reviews_deduped AS
SELECT order_id, review_score, review_creation_date
FROM (
    SELECT
        order_id,
        review_score,
        review_creation_date,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC, review_score DESC) AS row_num
    FROM order_reviews
) AS ranked
WHERE row_num = 1;

-- Step 2: Confirm deduped table has one record per order
SELECT COUNT(*) AS total_deduped FROM order_reviews_deduped; -- Expected: one row per unique order_id

SELECT COUNT(*) AS unique_orders FROM (
    SELECT order_id
    FROM order_reviews_deduped
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS remaining_dupes; -- Expected: 0

-- Step 3: Truncate original and reload from deduped
TRUNCATE TABLE order_reviews;

INSERT INTO order_reviews (order_id, review_score, review_creation_date)
SELECT order_id, review_score, review_creation_date
FROM order_reviews_deduped;

-- Step 4: Drop temporary table
DROP TEMPORARY TABLE order_reviews_deduped;

-- Step 5: Final verification
SELECT COUNT(*) AS total_after FROM order_reviews;

SELECT COUNT(*) AS remaining_duplicates
FROM (
    SELECT order_id
    FROM order_reviews
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS dupes; -- Expected: 0 remaining duplicates


-- ============================================================
-- Section 3: Missing and NULL Value Handling
-- ============================================================
-- Section 3 handles missing and NULL values across four tables
-- using distinct strategies on a per-column basis — no single
-- blanket approach is applied, as each decision is driven by
-- the nature of the missingness and the analytical implications
-- of the column. The dataset entering Section 4 reflects two
-- added flag columns, two structurally validated NULL sets,
-- and one verified payment type exclusion — each decision
-- documented with its analytical rationale.
-- ============================================================

-- 3A. products: flag null category names

-- 610 products carry no category name following the blank to NULL
-- conversion in Section 2B. No category can be reliably inferred
-- from other product attributes — imputing a category would
-- introduce false classification into the data. Records are
-- flagged so the EDA script can exclude them from category-based
-- analysis rather than silently dropping them.

-- Add flag column
ALTER TABLE products
ADD flag_null_category TINYINT(1);

-- Apply flag
UPDATE products 
SET flag_null_category = CASE
	WHEN product_category_name IS NULL THEN 1 ELSE 0 END; 

-- Verify: confirm 610 records flagged
SELECT COUNT(*) AS flagged_count
FROM products 
WHERE flag_null_category = 1; -- Expected: 610


-- 3B. products: flag suspect weight records

-- 6 products carry a NULL weight following the zero to NULL
-- conversion in Section 2C. Records are flagged so the EDA 
-- script can exclude them from freight ratio analysis rather 
-- than silently dropping them or introducing false weight
-- values into calculations.

-- Add flag column 
ALTER TABLE products 
ADD flag_suspect_weight TINYINT(1); 

-- Apply flag
UPDATE products 
SET flag_suspect_weight = CASE
	WHEN product_weight_g IS NULL THEN 1 ELSE 0 END; 

-- Verify: confirm 6 records flagged
SELECT COUNT(*) AS flagged_count
FROM products 
WHERE flag_suspect_weight = 1; -- Expected: 6


-- 3C. products: dimension nulls — structural validation, no action taken

-- 2 products carry NULL values in product_length_cm and
-- product_height_cm following the zero to NULL conversion in
-- Section 2D. With only 2 affected records no reliable imputation
-- path exists — averaging dimensions across 32,951 products would
-- introduce values with no meaningful relationship to these specific
-- products. NULL is left intentionally. These 2 records are excluded
-- from any dimension-based calculations in the EDA script.

-- Verify: confirm 2 null records in each dimension column
SELECT COUNT(*) AS null_length
FROM products 
WHERE product_length_cm IS NULL; -- Expected: 2 


SELECT COUNT(*) AS null_height
FROM products
WHERE product_height_cm IS NULL; -- Expected: 2


-- 3D. orders: timestamp nulls — structural validation, no action taken

-- Three timestamp columns carry NULL values following the empty
-- string to NULL conversion in Section 2E - order_approved_at 
-- (160 nulls), order_delivered_carrier_date (1,783 nulls), and
-- order_delivered_customer_date (2,965 nulls). Each NULL is 
-- structurally valid — orders that were never approved, never
-- picked up by a carrier, or never delivered have no timestamps
-- to record by definition. No imputation is appropriate here.

-- Verify: confirm expected null counts per timestamp column
SELECT COUNT(*) AS null_approved
FROM orders
WHERE order_approved_at IS NULL; -- Expected: 160

SELECT COUNT(*) AS null_carrier
FROM orders
WHERE order_delivered_carrier_date IS NULL; -- Expected: 1,783

SELECT COUNT(*) AS null_delivered
FROM orders
WHERE order_delivered_customer_date IS NULL; -- Expected: 2,965


-- 3E. order_payments: NULL payment type — verify and document

-- 3 records were set to NULL in Section 2A following the
-- not_defined to NULL conversion. These 3 records carry no
-- valid payment type and are excluded from payment type
-- segmentation in the EDA script. The remaining four valid
-- payment types — credit_card, boleto, voucher, debit_card —
-- are confirmed clean with no encoding inconsistencies.

-- Verify: confirm 3 NULL payment type records present
SELECT COUNT(*) AS null_payment_type
FROM order_payments
WHERE payment_type IS NULL; -- Expected: 3

-- Confirm four valid payment types remain 
SELECT payment_type, COUNT(*) AS record_count
FROM order_payments
WHERE payment_type IS NOT NULL
GROUP BY payment_type
ORDER BY record_count DESC; -- Expected: credit_card, boleto, voucher, debit_card


-- ============================================================
-- Section 4: Data Transformation and Type Conversion
-- ============================================================
-- Section 4 transforms encoded and raw columns into analytically
-- usable forms across seven tasks. All timestamp columns across
-- three tables are converted from VARCHAR to DATETIME, derived
-- columns are added to support delivery performance and freight
-- analysis, and all original columns are preserved as an audit
-- trail alongside their derived counterparts.
-- ============================================================

-- 4A. orders: convert timestamp columns VARCHAR → DATETIME

-- All five timestamp columns in orders were loaded as VARCHAR
-- because MySQL cannot reliably parse timestamp strings at load.
-- Converting to DATETIME now enables accurate date arithmetic
-- in tasks 4D and 4E — DATETIME comparison produces correct
-- results where VARCHAR string comparison does not.

ALTER TABLE orders MODIFY order_purchase_timestamp DATETIME; 
ALTER TABLE orders MODIFY order_approved_at DATETIME; 
ALTER TABLE orders MODIFY order_delivered_carrier_date DATETIME; 
ALTER TABLE orders MODIFY order_delivered_customer_date DATETIME; 
ALTER TABLE orders MODIFY order_estimated_delivery_date DATETIME; 

-- Verify: confirm nullable columns retain expected NULL counts
-- after conversion — a successful conversion preserves NULLs
SELECT COUNT(*) AS null_approved
FROM orders 
WHERE order_approved_at IS NULL; -- Expected: 160

SELECT COUNT(*) AS null_carrier
FROM orders 
WHERE order_delivered_carrier_date IS NULL; -- Expected: 1,783

SELECT COUNT(*) AS null_delivered
FROM orders 
WHERE order_delivered_customer_date IS NULL; -- Expected: 2,965

-- Verify: confirm format converted correctly
SELECT
    order_purchase_timestamp,
    order_approved_at,
    order_estimated_delivery_date
FROM orders
LIMIT 5;


-- 4B. order_items: convert shipping_limit_date VARCHAR → DATETIME

-- shipping_limit_date was loaded as VARCHAR for the same reason
-- as the orders timestamp columns — MySQL cannot reliably parse
-- timestamp strings at load time. Converting to DATETIME enables
-- for comparing shipping_limit_date against order_delivered_carrier_date
-- requires both columns to be DATETIME for accurate date arithmetic.

-- Convert column 
ALTER TABLE order_items
MODIFY shipping_limit_date DATETIME; 

-- Verify: confirm format converted correctly 
SELECT shipping_limit_date
FROM order_items
LIMIT 5; 

-- Verify: confirm no nulls introduced by conversion
SELECT COUNT(*) AS null_shipping_limit
FROM order_items
WHERE shipping_limit_date IS NULL;


-- 4C. order_reviews: convert review_creation_date VARCHAR → DATETIME

-- review_creation_date was loaded as VARCHAR for the same reason
-- as the orders and order_items timestamp columns. Converting to
-- DATETIME enables time-based analysis in the EDA script —
-- examining whether review scores change over time or correlate
-- with delivery timing requires DATETIME format for accurate
-- date arithmetic.

-- Convert column 
ALTER TABLE order_reviews
MODIFY review_creation_date DATETIME; 

-- Verify: confirm format converted correctly 
SELECT review_creation_date
FROM order_reviews
LIMIT 5; 

-- Verify: confirm no nulls introduced by conversion 
SELECT COUNT(*) AS null_review_date 
FROM order_reviews
WHERE review_creation_date IS NULL; 


-- 4D. orders: add is_late_delivery flag

-- Derived binary flag identifying orders where the actual delivery
-- date exceeded the estimated delivery date. Requires DATETIME
-- conversion in 4A. 

-- 1 = delivered late, 0 = delivered on time, NULL = not yet delivered.
-- NULL is intentional for undelivered orders — classifying them as
-- on time or late without a delivery date would introduce false data.

-- Add flag column
ALTER TABLE orders 
ADD COLUMN is_late_delivery TINYINT(1); 

-- Apply flag
UPDATE orders
SET is_late_delivery = CASE 
	WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
    WHEN order_delivered_customer_date IS NULL THEN NULL ELSE 0 END;

-- Verify: confirm flag distribution 
SELECT is_late_delivery, COUNT(*) AS distribution
FROM orders 
GROUP BY is_late_delivery; 
-- Results: 0 = 86,649 on time, 1 = 7,827 late, NULL = 2,965 undelivered 
-- Late delivery rate among all orders (includes undelivered): 7.9%
-- Late delivery rate among delivered orders only: 8.1% of 96,476


-- 4E. orders: add delivery_days_variance

-- Measures the difference in days between actual delivery date
-- and estimated delivery date. Negative values indicate early
-- delivery, positive values indicate late delivery, NULL where
-- order_delivered_customer_date is NULL — undelivered orders
-- cannot have a delivery variance calculated. This metric enables
-- average days late and maximum days late calculations.

-- Add column
ALTER TABLE orders 
ADD COLUMN delivery_days_variance DECIMAL(6,1);

-- Populate delivery days variance
UPDATE orders
SET delivery_days_variance = DATEDIFF(order_delivered_customer_date, order_estimated_delivery_date); 

-- Verify: confirm range is plausible and NULL count matches 
SELECT
	MIN(delivery_days_variance) AS min_variance, 
    MAX(delivery_days_variance) AS max_variance, 
    ROUND(AVG(delivery_days_variance),1) AS avg_variance, 
    SUM(CASE WHEN delivery_days_variance IS NULL THEN 1 ELSE 0 END) AS null_count
FROM orders; 
-- Results: min_variance = -147.0 (orders arrived 147 days earlier than estimated - 
-- extreme but plausible). max_variance = 188.0 (orders arrived 188 days after originally
-- estimated). avg_variance = -11.9 (orders on average arrive nearly 12 days earlier 
-- than estimated. Null count = 2,965 - matches Section 3D exactly. 

-- Delivery performance metrics 
SELECT 
	COUNT(*) AS late_orders, -- Count of orders which were delivered after estimated delivery date
    ROUND(AVG(delivery_days_variance),1) AS avg_days_late, -- When orders were late, on average, by how many days
    MAX(delivery_days_variance) AS max_days_late -- The largest gap between estimated delivery date and actual delivery date
FROM orders
WHERE is_late_delivery = 1; 
-- Results: 7,827 late orders confirmed. Average of 8.9  days late among late orders - 
-- When Olist misses the estimated date, the average miss is nearly 9 days. 188.0 days is the single worst, delivery failure. 


-- 4F. order_items: add freight_ratio

-- Measures freight cost as a proportion of product price. A
-- freight_ratio of 0.30 means freight costs 30% of the product
-- price — a significant cost burden pased to the customer. NULL guard
-- applied where price = 0 to prevent division by zero errors. This
-- metric enables freight burden analysis by product category and seller
-- in the EDA script — categories with high freight ratios relative
-- to product price represent the highest shipping cost burden.

-- Add column 
ALTER TABLE order_items 
ADD COLUMN freight_ratio DECIMAL(6,4);

-- Populate freight ratio
UPDATE order_items 
SET freight_ratio = CASE 
	WHEN price = 0 THEN NULL ELSE ROUND(freight_value / price, 4) END; 
    
-- Verify: confirm range is plausible and no unexpected nulls 
SELECT 
	MIN(freight_ratio) AS min_ratio, 
    MAX(freight_ratio) AS max_ratio, 
    ROUND(AVG(freight_ratio), 4) AS avg_ratio, 
    SUM(CASE WHEN freight_ratio IS NULL THEN 1 ELSE 0 END) AS null_count
FROM order_items; 
-- Some items carry zero freight value, which is plausible in the event a product 
-- is attached to a free shipping promotion. A max freight value of 26.2353 
-- signals the freight cost exceeds product price by more than 26 times -
-- plausible if the item is low-price with a high shipping  weight or distance
-- - an extreme outlier worth flagging. No zero-price records exist in order_items. 
    
    
-- 4G. products: translate category names Portuguese → English

-- product_category_name is stored in Portuguese throughout the
-- products table. Adding an English translation column enables
-- readable category-based analysis in the EDA script without
-- modifying the original Portuguese column. Two categories have
-- no translation in the product_category table — 'pc_gamer' and
-- 'portateis_cozinha_e_preparadores_de_alimentos' — manually
-- translated and applied in a second UPDATE.

-- Add English category column 
ALTER TABLE products
ADD COLUMN product_category_english VARCHAR(100); 

-- Step 1: Populate via JOIN to product_category translation table - 71 of 73 distinct categories 
UPDATE products p
JOIN product_category pc 
ON p.product_category_name = pc.product_category_name
SET p.product_category_english = pc.product_category_name_english; 

-- Step 2: Manually translate the two untranslated categories 
UPDATE products 
SET product_category_english = CASE
	WHEN product_category_name = 'pc_gamer' THEN 'PC Gaming' 
    WHEN product_category_name = 'portateis_cozinha_e_preparadores_de_alimentos' THEN 'Portable Kitchen Appliances'
    ELSE product_category_english END;
    
-- Verify: confirm translation coverage 
SELECT COUNT(*) AS translated_count 
FROM products
WHERE product_category_english IS NOT NULL; -- Expected: 32,341 (32,951 - 610 null category records) 

SELECT COUNT(*) AS untranslated_count 
FROM products 
WHERE product_category_english IS NULL 
AND product_category_name IS NOT NULL; -- Expected: 0 - all named categories should now carry an English translation

-- Confirm two manual translations applied correctly 
SELECT product_category_name, product_category_english
FROM products 
WHERE product_category_name IN ('pc_gamer',  'portateis_cozinha_e_preparadores_de_alimentos')
LIMIT 5; 


-- ============================================================
-- Section 5: Deduplication Validation and Referential Integrity Recheck
-- ============================================================
-- Section 5 performs deduplication validation, referential integrity
-- rechecks across all eight tables post-cleaning, and date conversion
-- confirmation. This ensures the relational structure is sound before
-- derived metrics are created in Section 6.
-- ============================================================

-- 5A. Confirm order_reviews deduplication held

-- Validating that the Section 2F deduplication is intact and no
-- subsequent operations reintroduced duplicate review records.

-- Confirm zero duplicate orders remain 
SELECT COUNT(order_id) AS duplicates
FROM order_reviews 
GROUP BY order_id
HAVING duplicates > 1; -- Expected: 0 

-- Confirm total row count reflects deduplication
SELECT COUNT(*) AS total_reviews 
FROM order_reviews; -- Expected: 98,673


-- 5B. Referential integrity recheck across all table relationships

-- Rerunning all six JOIN checks from Section 1F to confirm records
-- remain after all cleaning operations in Sections 2 through 4.
-- Note that order_reviews now carries 98,673 records following
-- Section 2F deduplication.

-- orders to customers
SELECT COUNT(*) AS orders_matched_to_customers
FROM orders o 
JOIN customers c 
ON o.customer_id = c.customer_id;  -- Expected: 99,441

-- order_items to orders
SELECT COUNT(*) AS items_matched_to_orders
FROM order_items oi 
JOIN orders o 
ON oi.order_id = o.order_id; -- Expected: 112,650

-- order_items to products
SELECT COUNT(*) AS items_matched_to_products 
FROM order_items oi 
JOIN products p 
ON oi.product_id = p.product_id; -- Expected: 112,650

-- order_items to sellers
SELECT COUNT(*) AS items_matched_to_sellers
FROM order_items oi 
JOIN sellers s 
ON oi.seller_id = s.seller_id; -- Expected: 112,650

-- order_reviews to orders 
SELECT COUNT(*) AS reviews_matched_to_orders
FROM order_reviews ors
JOIN orders o 
ON ors.order_id = o.order_id; -- Expected: 98,673 - reflects post-deduplication row count

-- order_payments to orders 
SELECT COUNT(*) AS payments_matched_to_orders
FROM order_payments os 
JOIN orders o 
ON os.order_id = o.order_id; -- Expected: 103,886 


-- 5C. Confirm all date conversions succeeded

-- Verifying DATETIME format is correct across all three tables
-- with converted timestamp columns. The 00:00:00 time component
-- on order_estimated_delivery_date and review_creation_date is
-- expected — both columns were recorded at date-level precision
-- only in the source data.

-- orders: five timestamp columns
SELECT 
	order_purchase_timestamp, 
    order_approved_at, 
    order_delivered_carrier_date, 
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM orders
LIMIT 5; -- All five columns confirmed in YYYY-MM-DD HH:MM:SS format 
-- order_estimated_delivery_date shows 00:00:00 time - expected, date-level precision only in source data

-- order_items: shipping limit date
SELECT 
	shipping_limit_date
FROM order_items
LIMIT 5; -- Confirmed in YYYY-MM-DD HH:MM:SS format with valid time captured

-- order_reviews: review creation date
SELECT 
	review_creation_date
FROM order_reviews
LIMIT 5; -- Confirmed in YYYY-MM-DD HH:MM:SS format
-- 00:00:00 time component expected - date-level precision only in source data


-- 5D. Confirm all flag and derived columns populated correctly 

SELECT COUNT(*) AS record_counts FROM products WHERE flag_null_category = 1; -- Expected: 610
SELECT COUNT(*) AS record_counts FROM products WHERE flag_suspect_weight = 1; -- Expected: 6
SELECT COUNT(*) AS record_counts FROM orders WHERE is_late_delivery = 1; -- Expected: 7,827
SELECT COUNT(*) AS record_counts FROM orders WHERE is_late_delivery = 0; -- Expected: 88,649
SELECT COUNT(*) AS record_counts FROM orders WHERE is_late_delivery IS NULL; -- Expected: 2,965 
SELECT COUNT(*) AS record_counts FROM orders WHERE delivery_days_variance IS NULL; -- Expected: 2,965
SELECT COUNT(*) AS record_counts FROM order_items WHERE freight_ratio IS NULL; -- Expected: 0 
SELECT COUNT(*) AS record_counts FROM products WHERE product_category_english IS NOT NULL; -- Expected: 32,341


-- ============================================================
-- Section 6: Derived Metrics and Final Validation
-- ============================================================
-- Section 6 creates order-level and seller-level derived metrics
-- that the EDA script depends on. This section represents the most
-- technically complex queries in the cleaning script — spanning
-- multiple tables simultaneously via JOINs. The section closes
-- with a post-cleaning NULL audit and row count reconciliation
-- confirming the data is analytically ready.
-- ============================================================

-- 6A. Add order-level revenue to orders table

-- Adding order_revenue as a derived column to the orders table
-- by aggregating payment_value per order_id from order_payments.
-- This accounts for the 2,246 orders with multiple payment records. 


-- Add column 
ALTER TABLE orders 
ADD COLUMN order_revenue DECIMAL(10,2); 

-- Populate via JOIN to order_payments subquery 
UPDATE orders o 
JOIN (
	SELECT 
		order_id, 
		ROUND(SUM(payment_value),2) AS total_order_revenue
	FROM order_payments 
	GROUP BY order_id 
) AS os
ON o.order_id = os.order_id
SET o.order_revenue = os.total_order_revenue; 

-- Verify: confirm total revenue matches Section 1H baseline 
SELECT 
	ROUND(SUM(order_revenue),2) AS total_order_revenue
FROM orders; -- Expected: $16,008,872.12 - matches baseline

-- Verify: confirm no orders have NULL revenue where payment exists 
SELECT COUNT(*) AS null_revenue_count 
FROM orders o 
JOIN order_payments os 
ON o.order_id = os.order_id 
WHERE o.order_revenue IS NULL; -- Expected: 0 


-- 6B. Create seller_summary table

-- Summarizing seller-level performance across five metrics spanning
-- five tables. Each metric is pre-aggregated in its own subquery.
-- LEFT JOIN used throughout to retain all 3,095 sellers
-- even where some metrics are NULL — sellers with no reviews or
-- no late deliveries should still appear in the summary.

CREATE TABLE seller_summary AS
SELECT 
	b1.seller_id, 
    b1.total_orders, 
    b1.total_revenue, 
    b2.late_delivery_rate, 
    b3.avg_review_score, 
    b4.avg_freight_ratio
FROM (
-- Building block 1: order volume and revenue per seller 
SELECT 
	oi.seller_id,
	COUNT(DISTINCT oi.order_id) AS total_orders, 
    ROUND(SUM(os.payment_value),2) AS total_revenue
FROM order_items oi
JOIN order_payments os ON oi.order_id = os.order_id
GROUP BY oi.seller_id
) AS b1
LEFT JOIN (
-- Building block 2: late delivery rate per seller 
SELECT 
	oi.seller_id, 
    ROUND(AVG(o.is_late_delivery),4) AS late_delivery_rate
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id 
) AS b2 on b1.seller_id = b2.seller_id
LEFT JOIN (
-- Building block 3: average review score per seller
SELECT 
	oi.seller_id, 
	ROUND(AVG(review_score),2) AS avg_review_score
FROM order_items oi 
JOIN order_reviews ors ON oi.order_id = ors.order_id
GROUP BY oi.seller_id
) AS b3 on b1.seller_id = b3.seller_id
LEFT JOIN (
-- Building block 4: average freight ratio per seller
SELECT 
	seller_id, 
    ROUND(AVG(freight_ratio),4) AS avg_freight_ratio
FROM order_items 
GROUP BY seller_id
) AS b4 on b1.seller_id = b4.seller_id; 

-- Verify: confirm row count matches full seller base
SELECT COUNT(*) AS seller_count
FROM seller_summary; -- Expected: 3,095

-- Verify: spot check a sample of seller records 
SELECT * FROM seller_summary LIMIT 5; 
-- NULL values in late_delivery_rate and avg_review_score are structurally 
-- valid and represent sellers with insufficient delivered or review history

-- Verify: confirm no seller_id is null in summary 
SELECT COUNT(*) AS null_seller_id
FROM seller_summary
WHERE seller_id IS NULL; -- Expected: 0


-- 6C. Post-cleaning NULL audit 

-- Rerunning null checks across all four tables where cleaning
-- operations introduced or modified NULL values. 

-- products: null state confirmation
SELECT COUNT(*) AS null_category
FROM products 
WHERE product_category_name IS NULL; -- Expected: 610

SELECT COUNT(*) AS zero_weight
FROM products 
WHERE product_weight_g IS NULL; -- Expected: 6

SELECT COUNT(*) AS null_dimensions
FROM products 
WHERE product_length_cm IS NULL; -- Expected: 2

SELECT COUNT(*) AS null_dimensions
FROM products 
WHERE product_height_cm IS NULL; -- Expected: 2

-- orders: timestamp null confirmation 
SELECT
	SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approved, -- Expected: 160
    SUM(CASE WHEN order_delivered_carrier_date IS NULL THEN 1 ELSE 0 END) AS null_carrier, -- Expected: 1,783
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivered -- Expected: 2,965
FROM orders; 

-- order_payments: null payment type confirmation 
SELECT COUNT(*) AS null_count
FROM order_payments 
WHERE payment_type IS NULL; -- Expected: 3


-- 6D. Row count reconciliation 

SELECT 'customers' AS table_name, COUNT(*) AS records FROM customers -- Expected: 99,441
UNION ALL 
SELECT 'order_items' AS table_name, COUNT(*) AS records FROM order_items -- Expected: 112,650
UNION ALL 
SELECT 'order_payments' AS table_name, COUNT(*) AS records FROM order_payments -- Expected: 103,886
UNION ALL 
SELECT 'order_reviews' AS table_name, COUNT(*) AS records FROM order_reviews -- Expected: 98,673
UNION ALL 
SELECT 'orders' AS table_name, COUNT(*) AS records FROM orders -- Expected: 99,441
UNION ALL 
SELECT 'product_category' AS table_name, COUNT(*) AS records FROM product_category -- Expected: 71
UNION ALL 
SELECT 'products' AS table_name, COUNT(*) AS records FROM products -- Expected: 32,951
UNION ALL 
SELECT 'sellers' AS table_name, COUNT(*) AS records FROM sellers; -- Expected: 3,095
