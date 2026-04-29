

-- ============================================================
-- Home Credit Risk — Data Cleaning and Transformation Script
-- ============================================================
-- This project cleans and transforms 307,511 loan application
-- records from Home Credit, a financial institution serving
-- underbanked borrowers, sourced from the Home Credit Default
-- Risk dataset. Of the 122 columns in the original
-- dataset, 25 were retained based on their direct bearing on
-- borrower creditworthiness, financial capacity, and employment
-- stability. Property-related columns averaging 58% missing
-- values, contact flag columns with near-zero analytical
-- variance, and credit bureau inquiry columns with correlations
-- near zero against default outcomes were excluded from scope.
-- This script covers data cleaning and transformation only.
-- The companion EDA script applies the cleaned dataset to answer
-- the core analytical question: what combination of borrower
-- characteristics separates low-risk borrowers from high-risk ones.

-- Author: Arohit Talari       
-- Dataset: application_train.csv     
-- Source: https://www.kaggle.com/competitions/home-credit-default-risk/data        
-- MySQL Version: 9.5.0
-- ============================================================


-- ============================================================
-- Table Creation
-- ============================================================
use home_credit;

CREATE TABLE application_train (

    SK_ID_CURR                  INT             NOT NULL, -- Primary key; uniquely identifies each loan application record

    -- Binary outcome variable; 1 = borrower defaulted (missed payments on early installments), 0 = borrower did not default.
    -- Every default rate calculation, segmentation, and risk comparison in both scripts references this column as the dependent variable.
    TARGET                      TINYINT(1)      NOT NULL,

    NAME_CONTRACT_TYPE          VARCHAR(30)     NOT NULL, -- Two values: Cash loans, Revolving loans

    -- FLOAT arithmetic introduces rounding errors in financial calculations; compounded across 307,511 records these errors
    -- become analytically meaningful. DECIMAL(15,4) enforces precision non-negotiable in financial data.
    AMT_CREDIT                  DECIMAL(15,4)   NOT NULL,

    -- Same rationale as AMT_CREDIT. Additionally, this column contains extreme outliers — max value is $117,000,000
    -- against a 99th percentile of $472,500. Outlier handling is addressed in Section 2.
    AMT_INCOME_TOTAL            DECIMAL(15,4)   NOT NULL,

    -- Nullable; 12 records in the source data carried no annuity value. Imputation strategy addressed in Section 3.
    AMT_ANNUITY                 DECIMAL(15,4)   NULL,

    -- Nullable; all 278 missing values belong exclusively to revolving loan records. Structurally expected —
    -- revolving credit does not finance a specific purchase, so no goods price exists by design.
    AMT_GOODS_PRICE             DECIMAL(15,4)   NULL,

    -- Three distinct values in source data: F, M, XNA. XNA affects 4 records and is not a valid gender category —
    -- addressed in Section 2.
    CODE_GENDER                 VARCHAR(3)      NOT NULL,

    -- Stored as negative integers representing days elapsed prior to the application date; no positive values exist.
    -- Transformed into a readable age in years in Section 4.
    DAYS_BIRTH                  INT             NOT NULL,

    -- Five education tiers; default rates vary from 1.8% at academic degree level to 10.9% at lower secondary —
    -- among the strongest demographic default rate signals in the dataset.
    NAME_EDUCATION_TYPE         VARCHAR(50)     NOT NULL,

    -- Six family status categories; 'Unknown' appears in 2 records and is addressed in Section 2.
    NAME_FAMILY_STATUS          VARCHAR(30)     NOT NULL,

    -- Eight income types: Working, Commercial associate, Pensioner, State servant, Unemployed, Student,
    -- Businessman, Maternity leave. Unemployed borrowers carry a 36.4% default rate against an 8.1% overall
    -- average — the single highest-risk income segment in the dataset.
    NAME_INCOME_TYPE            VARCHAR(50)     NOT NULL,

    -- Six housing types; renters carry a 12.3% default rate, the highest among all housing categories.
    NAME_HOUSING_TYPE           VARCHAR(50)     NOT NULL,

    -- Most values fall between 0 and 5; records with values exceeding 10 are flagged as suspect entries
    -- in Section 2.
    CNT_CHILDREN                TINYINT         NOT NULL,

    -- Source data encodes this field as a float (1.0, 2.0, 3.0); loading as INT would cause truncation
    -- errors during import. 2 records carried no value. Cast to integer in Section 4.
    CNT_FAM_MEMBERS             DECIMAL(5,1)    NULL,

    -- Binary; Y = borrower owns a car, N = borrower does not. Governs null handling logic for OWN_CAR_AGE —
    -- where FLAG_OWN_CAR = N, OWN_CAR_AGE is expected to be NULL.
    FLAG_OWN_CAR                VARCHAR(1)      NOT NULL,

    FLAG_OWN_REALTY             VARCHAR(1)      NOT NULL, -- Binary; Y = borrower owns property, N = borrower does not

    -- Nullable; 66% of records are NULL, structurally valid as nulls map directly to FLAG_OWN_CAR = N.
    -- 5 records where FLAG_OWN_CAR = Y also carried missing car age and loaded as 0. Full null
    -- handling logic documented in Section 3.
    OWN_CAR_AGE                 DECIMAL(5,1)    NULL,

    -- Stored as negative integers representing days employed prior to application date, mirroring DAYS_BIRTH encoding.
    -- 55,374 records carry a value of 365,243 — a systematic placeholder for pensioners and unemployed borrowers, not a
    -- true employment duration. This anomaly is addressed in Section 3 and drives the derived employment tenure column in Section 4.
    DAYS_EMPLOYED               INT             NOT NULL,

    -- 31.3% of records are NULL; missingness is non-random and shows near-total overlap with the DAYS_EMPLOYED
    -- 365,243 anomaly records — confirming these are pensioners or unemployed borrowers with no occupation on record.
    -- This relationship is resolved with DAYS_EMPLOYED in Section 3.
    OCCUPATION_TYPE             VARCHAR(50)     NULL,

    -- 58 distinct employer organization categories; Transport type 3 carries the highest default rate
    -- in the dataset at 15.8%.
    ORGANIZATION_TYPE           VARCHAR(50)     NOT NULL,

    -- External credit score proxy sourced from a third-party bureau. Correlation with default outcome: -0.16,
    -- indicating higher scores predict lower default risk. Only 0.2% of records are missing — imputed in Section 3.
    EXT_SOURCE_2                FLOAT           NULL,

    -- External credit score proxy; strongest predictor of default among all columns at -0.18 correlation.
    -- 19.8% of records are missing and missingness is non-random — records without EXT_SOURCE_3 default at
    -- 9.3% versus 7.8% where it is present. Flagged rather than imputed; addressed in Section 3.
    EXT_SOURCE_3                FLOAT           NULL,

    -- Three-tier regional risk score: 1 = low risk, 2 = medium risk, 3 = high risk. Default rates scale
    -- cleanly with the rating at 4.8%, 7.9%, and 11.1% respectively — confirming reliability as a risk signal.
    REGION_RATING_CLIENT        TINYINT         NOT NULL,

    -- Same methodology as REGION_RATING_CLIENT, adjusted to account for city-level risk within each region.
    REGION_RATING_CLIENT_W_CITY TINYINT         NOT NULL,

    PRIMARY KEY (SK_ID_CURR)

);

-- ============================================================
-- LOAD Comment(s) 
-- ============================================================
-- While loading the data into MySQL, I've made three intentional decisions:

-- OPTIONALLY ENCLOSED BY '"', so string fields containing commas within 
-- their values wouldn't be misread as field delimiters. This ensured MySQL 
-- treats anything inside double quotes as a single field value regardless 
-- of internal commas. 

-- IGNORE 1 ROWS so MySQL understands the first row of the CSV is a header 
-- row containing column names, not data. Without this instruction, MySQL 
-- would attempt to load the header as a data record and either throw a type
-- mismatch error or insert a corrupt first row. 

-- LINES TERMINATED BY '\n' was utilized to match how Mac-generated CSVs 
-- terminates lines - without it, MySQL may misread row boundaries or carry
-- invisible characters into field values. 


-- ============================================================
-- Section 1: Initial Data Profiling and Baseline Audit
-- ============================================================
-- Section 1 produces no changes to the data. It is observation only.
-- Every query in this section is a SELECT - nothing is updated, deleted, or inserted. 
-- The purpose is to establish what the data actually contains before any cleaning
-- decisions are made in Sections 2 through 5. 
-- ============================================================

-- 1A. Record Count Confirmation - Expecting 307,511 records

SELECT COUNT(*) FROM application_train; -- 307,511 records have been verified 

-- 1B. NULL Count(s)
SELECT 
	SUM(CASE WHEN AMT_ANNUITY IS NULL THEN 1 ELSE 0 END) AS null_amt_annuity, -- NULL AMT_ANNUITY: 12 
    SUM(CASE WHEN AMT_GOODS_PRICE IS NULL THEN 1 ELSE 0 END) AS null_amt_goods_price, -- NULL AMT_GOODS_PRICE: 278
    SUM(CASE WHEN CNT_FAM_MEMBERS IS NULL THEN 1 ELSE 0 END) AS null_cnt_fam_members, -- NULL CNT_FAM_MEMBERS: 2
    SUM(CASE WHEN OWN_CAR_AGE IS NULL THEN 1 ELSE 0 END) AS null_own_car_age,  -- NULL OWN_CAR_AGE: 202924
    SUM(CASE WHEN OCCUPATION_TYPE IS NULL THEN 1 ELSE 0 END) AS null_occupation_type, -- NULL OCCUPATION_TYPE: 96391
    SUM(CASE WHEN EXT_SOURCE_2 IS NULL THEN 1 ELSE 0 END) AS null_ext_source_2, -- NULL EXT_SOURCE_2: 660
    SUM(CASE WHEN EXT_SOURCE_3 IS NULL THEN 1 ELSE 0 END) AS null_ext_source_3 -- NULL EXT_SOURCE_3: 60965
FROM application_train; 

-- 1C. DISTINCT value checks on categorical columns

SELECT DISTINCT name_contract_type -- 2 contract types are present: Cash Loans, Revolving Loans
FROM application_train; -- Cash Loans default at 8.3%, nearly 50% higher than revolving loans (5.5%)

SELECT DISTINCT code_gender -- 3 gender types are present: M, F, XNA - M and F are two valid gender categories whose presence is expected 
FROM application_train; -- XNA appears in 4 records and is not a valid gender category - it has been incorrectly encoded and needs to be resolved before any gender-based analysis is run 

SELECT DISTINCT name_education_type -- 5 education tiers are present, no unexpected values, no nulls, no encoding errors. The column is clean as loaded 
FROM application_train; -- Default rate range: academic degree = 1.8% to lower secondary = 10.9% - a 6x difference

SELECT DISTINCT name_family_status -- 5 family statuses are present. No formatting inconsistencies, no duplicates 
FROM application_train; -- 'Unknown' appears in 2 records - encoding needs to be resolved before any family status segmentation is run 

SELECT DISTINCT name_income_type -- 8 income types are present. No formatting inconsistencies, no duplicates, no nulls. The column is clean as loaded
FROM application_train; -- 'Maternity Leave' and 'Businessman' only contain 5 and 10 records, respectively. They are statistically too small to draw reliable conclusions from in the EDA script

SELECT DISTINCT name_housing_type -- 6 housing types are present. No formatting inconsistencies, no duplicates, no nulls. The column is clean as loaded
FROM application_train; -- 'Office apartment' and 'Co-op apartment' contain 2,617 and 1,122 records, respectively. They are the smallest segments in the column and conclusions drawn from them in EDA should be treated with appropriate caution

SELECT DISTINCT occupation_type -- 18 occupation types are present. No formatting inconsistencies, no invalid encodings among the legitimate categories
FROM application_train; -- NULL appears as a distinct value in this column, representing 96,391 records - 31.3% of the dataset. This must be explicitly addressed alongside days_employed in Section 3

SELECT DISTINCT organization_type -- 58 different employer organizations are present. No formatting inconsistencies, no invalid encodings, no nulls. The column is clean as loaded
FROM application_train; -- Volume distribution among organization_type is materially uneven - several organization types contain fewer than 100 records, making default rate conclusions from those segments statistically unreliable

SELECT DISTINCT flag_own_car -- Two valid binary values confirmed: Y and N. No nulls, no unexpected encodings, no formatting inconsistencies. Column is clean as loaded
FROM application_train; -- This column's primary analytical role is as a governance column for own_car_age - where flag_own_car = N, own_car_age is expected to be NULL

SELECT DISTINCT flag_own_realty -- Two valid binary values confirmed: Y and N. No nulls, no unexpected encodings, no formatting inconsistencies. Column is clean as loaded
FROM application_train; -- Property ownership is a stronger, more stable asset than car ownership - this will be cross-referenced against housing type and income level in the EDA script

-- 1D. Range and Distribution on numeric columns

-- The purpose of this query is to flag any anomalies across numeric columns
-- The MAX value of days_employed returns 365,243 days - this is an extreme anomaly will be flagged and addressed in Section 2
-- The MAX value of amt_income_total returns $117,000,000 against a 99th percentile of $472,500 - this is an extreme outlier that needs to be flagged and addressed in Section 3
SELECT 
	MIN(days_birth) AS min_days_birth, MAX(days_birth) AS max_days_birth, ROUND(AVG(days_birth),0) AS avg_days_birth,
    MIN(days_employed) AS min_days_employed, MAX(days_employed) AS max_days_employed, ROUND(AVG(days_employed),0) AS avg_days_employed, 
    ROUND(MIN(amt_income_total),0) AS min_income, ROUND(MAX(amt_income_total),0) AS max_income, ROUND(AVG(amt_income_total),0) AS avg_income,
    ROUND(MIN(amt_credit),0) AS min_credit, ROUND(MAX(amt_credit),0) AS max_credit, ROUND(AVG(amt_credit),0) AS avg_credit,
    ROUND(MIN(amt_annuity),0) AS min_amt_annuity, ROUND(MAX(amt_annuity),0) AS max_amt_annuity, ROUND(AVG(amt_annuity),0) AS avg_amt_annuity,
    ROUND(MIN(amt_goods_price),0) AS min_goods_price, ROUND(MAX(amt_goods_price),0) AS max_goods_price, ROUND(AVG(amt_goods_price),0) AS avg_goods_price,
    ROUND(MIN(own_car_age),0) AS min_own_car_age, ROUND(MAX(own_car_age),0) AS max_own_car_age, ROUND(AVG(own_car_age),0) AS avg_own_car_age,
    ROUND(MIN(ext_source_2),4) AS min_ext_source2, ROUND(MAX(ext_source_2),4) AS max_ext_source2, ROUND(AVG(ext_source_2),4) AS avg_ext_source2,
    ROUND(MIN(ext_source_3),4) AS min_ext_source3, ROUND(MAX(ext_source_3),4) AS max_ext_source3, ROUND(AVG(ext_source_3),4) AS avg_ext_source3,
    MIN(cnt_children) AS min_children, MAX(cnt_children) AS max_children, ROUND(AVG(cnt_children),2) AS avg_children,
    ROUND(MIN(cnt_fam_members),0) AS min_cnt_fam_members, ROUND(MAX(cnt_fam_members),0) AS max_cnt_fam_members, ROUND(AVG(cnt_fam_members),0) AS avg_cnt_fam_members
FROM application_train; 

-- 1E. Average default rate (baseline) 

SELECT AVG(target) FROM application_train; -- Average default rate = 8.07% - this is the benchmark for every subsequent comparison of default rate


-- ============================================================
-- Section 2: Incorrect and Invalid Value Correction 
-- ============================================================
-- Section 2 resolves incorrect and invalid values across key columns before
-- any missing value handling occurs. Incorrect values must be addressed first
-- because conflating them with missing values and running imputation across both
-- risks replacing bad data with statistically derived values that appear legitimate
-- but aren't. Resolving invalid encodings first ensures Section 3 is working with
-- a clean categorical and numerical foundation before any imputation decisions are made.
-- ============================================================

-- 2A. code_gender: XNA → NULL

-- XNA is not a valid gender category. 4 records carry this encoding. 
-- Setting to NULL before any gender-based segmentation is run. 

-- Before count: confirm count of records that carry 'XNA' 
SELECT COUNT(*) AS before_count FROM application_train
WHERE code_gender = 'XNA'; -- Count = 4 records

-- Modify code_gender constraints - Previously code_gender was loaded in as a NOT NULL column, updating to reflect a column which allows NULL before applying correction to values
ALTER TABLE application_train 
MODIFY COLUMN code_gender VARCHAR(3) NULL; 

-- Apply correction
UPDATE application_train
SET code_gender = NULL 
WHERE code_gender = 'XNA';

-- After count: confirm count of records that carry 'XNA' 
SELECT COUNT(*) AS after_count FROM application_train
WHERE code_gender = 'XNA';


-- 2B. name_family_status: Unknown → NULL

-- 'Unknown' is not a valid family status category. 2 records carry this encoding.
-- Setting to NULL before any family status segmentation is run.

-- Before count: confirm count of records that carry 'Unknown'
SELECT COUNT(*) AS before_count FROM application_train
WHERE name_family_status = 'Unknown'; -- Count = 2 records

-- Modify name_family_status constraints - Previously name_family_status was loaded in as a NOT NULL column, updating to reflect a column which allows NULL before applying correction to values
ALTER TABLE application_train 
MODIFY COLUMN name_family_status VARCHAR(30) NULL; 

-- Apply correction
UPDATE application_train
SET name_family_status = NULL 
WHERE name_family_status = 'Unknown';

-- After count: confirm count of records that carry 'Unknown'
SELECT COUNT(*) AS after_count FROM application_train
WHERE name_family_status = 'Unknown';


-- 2C. cnt_children: Flag records exceeding 10

-- Most values fall between 0 and 5. Records with values exceeding 10
-- are statistically improbable and flagged as suspect entries.
-- Records are not dropped — they are flagged for transparency and
-- excluded from child-count segmentation in the EDA script.

-- Before: confirm count of records where cnt_children > 10
SELECT COUNT(*) AS before_count FROM application_train 
WHERE cnt_children > 10; -- Count = 8 records 

-- Add flag column 
ALTER TABLE application_train
ADD flag_suspect_children TINYINT(1);

-- Apply Flag
UPDATE application_train
SET FLAG_SUSPECT_CHILDREN = 
CASE 
	WHEN cnt_children > 10 THEN 1 ELSE 0 END; 

-- After: confirm flagged record count
SELECT COUNT(*) AS after_count FROM application_train 
WHERE flag_suspect_children = 1;


-- 2D. amt_income_total: Flag extreme outliers 

-- Max value of $117,000,000 against a 99.9th percentile of $900,000.
-- The 99.9th percentile was chosen over the 99th ($472,500) because values
-- between $472,500 and $900,000 represent high but plausible incomes.
-- Borrowers earning above $900,000 annually are statistically implausible
-- customers for a financial institution serving underbanked populations.
-- Records are flagged, not dropped. 

-- Before: confirm count of records where amt_income_total > 900000
SELECT COUNT(*) AS before_count FROM application_train
WHERE amt_income_total > 900000; -- 278 records

-- Add flag column
ALTER TABLE application_train
ADD FLAG_INCOME_OUTLIER TINYINT(1);

-- Apply flag column
UPDATE application_train
SET FLAG_INCOME_OUTLIER = 
CASE 
	WHEN amt_income_total > 900000 THEN 1 ELSE 0 END; 

-- After: confirm flagged record count 
SELECT COUNT(*) AS after_count FROM application_train
WHERE flag_income_outlier = 1;


-- ============================================================
-- Section 3: Missing and NULL Value Handling 
-- ============================================================
-- Section 3 handles missing and NULL values across 7 columns using
-- five distinct resolutions: imputing missing values with each column's
-- respective median, imputing missing values with a fixed value, adding
-- binary flag columns to preserve records where imputation would introduce
-- analytical error, reclassifying NULL values as a meaningful category
-- where missingness was non-random and identifiable, and structural
-- validation with no action taken. A single blanket approach was not
-- applied — each decision was driven by the nature of the missingness
-- and the analytical implications of treating every column the same.
-- The dataset entering Section 4 reflects seven resolved NULL scenarios,
-- three added flag columns, and one reclassified category — each decision
-- documented with its analytical rationale.
-- ============================================================

-- 3A. amt_annuity: Impute with median

-- 12 records carry no annuity value. All 12 are cash loans, non-defaulted,
-- with large credit amounts. Volume is low enough that median imputation
-- introduces minimal bias. Median calculated as 24903.0 against a mean of
-- 27108.6 — the right-skewed distribution of annuity amounts confirms median
-- is the more representative central value for imputation.

-- Median calculation 
SELECT ROUND(AVG(amt_annuity),1) AS median
FROM (
SELECT 
	amt_annuity AS amt_annuity, 
    ROW_NUMBER() OVER(ORDER BY amt_annuity ASC) AS row_num,
    COUNT(*) OVER() as total_count
FROM application_train 
WHERE amt_annuity IS NOT NULL
) AS subquery
WHERE row_num IN (
	FLOOR((total_count + 1) / 2), 
    FLOOR((total_count + 2) / 2)
);

-- Before: confirm 12 null records
SELECT COUNT(*) AS before_count FROM application_train
WHERE amt_annuity IS NULL;

-- Apply imputation
UPDATE application_train 
SET amt_annuity = 24903.0
WHERE amt_annuity IS NULL; 

-- After: confirm 0 null records remain 
SELECT COUNT(*) AS after_count FROM application_train 
WHERE amt_annuity IS NULL;


-- 3B. cnt_fam_members: Impute with 1

-- 2 records carry no family member count. Both records have cnt_children = 0
-- and name_family_status encoded as 'Unknown' — set to NULL in Section 2.
-- A value of 1.0 representing a single-person household is the most defensible
-- imputation given the absence of children and unknown family status.

-- Before: confirm 2 null records
SELECT COUNT(*) AS before_count FROM application_train 
WHERE cnt_fam_members IS NULL; 

-- Apply imputation 
UPDATE application_train
SET cnt_fam_members = 1
WHERE cnt_fam_members IS NULL; 

-- After: confirm 0 null records remain 
SELECT COUNT(*) AS after_count FROM application_train 
WHERE cnt_fam_members IS NULL; 


-- 3C. ext_source_2: Impute with median 

-- 660 records carry no ext_source_2 value — 0.2% of the dataset.
-- Volume is low enough that median imputation introduces minimal bias.
-- Median of 0.5660 calculated against a mean of 0.5144 — the right-skewed
-- distribution of external scores confirms median as the more representative
-- central value, protecting against the influence of high-score outliers at
-- the tail of the distribution.

-- Median calculation 
SELECT ROUND(AVG(ext_source_2),4) AS median
FROM (
SELECT
	ext_source_2, 
    ROW_NUMBER() OVER(ORDER BY ext_source_2) AS row_num, 
    COUNT(*) OVER() AS total_count
FROM application_train 
WHERE ext_source_2 IS NOT NULL
) AS subquery
WHERE row_num IN (
	FLOOR((total_count + 1) / 2),
    FLOOR((total_count + 2) / 2)
);

-- Before: confirm 660 null records 
SELECT COUNT(*) AS before_count FROM application_train
WHERE ext_source_2 IS NULL; 

-- Apply imputation 
UPDATE application_train 
SET ext_source_2 = 0.5660
WHERE ext_source_2 IS NULL; 

-- After: confirm 0 null records remain 
SELECT COUNT(*) AS after_count FROM application_train
WHERE ext_source_2 IS NULL; 


-- 3D. amt_goods_price: Flag, do not impute

-- 278 records carry no goods price value. All 278 belong exclusively to
-- revolving loan records — confirmed in Section 1. Revolving credit does
-- not finance a specific purchase so no goods price exists by design.
-- Imputing a goods price onto a revolving loan would be analytically
-- incorrect. Records are flagged for transparency and excluded from
-- loan-to-value ratio calculations in the EDA script.

-- Before: confirm 278 null records 
SELECT COUNT(*) AS before_count FROM application_train
WHERE amt_goods_price IS NULL; 

-- Add flag column 
ALTER TABLE application_train 
ADD flag_no_goods_price TINYINT(1); 

-- Apply flag 
UPDATE application_train 
SET flag_no_goods_price = CASE
	WHEN amt_goods_price IS NULL THEN 1 ELSE 0 END;  

-- After: confirm 278 records flagged 
SELECT COUNT(*) AS after_count FROM application_train 
WHERE flag_no_goods_price = 1; 


-- 3E. occupation_type: Reclassify NULLs as 'Not Employed / Unknown'

-- 96,391 records carry no occupation type — 31.3% of the dataset.
-- Missingness is non-random: diagnostic analysis confirmed near-total
-- overlap between NULL occupation_type records and the days_employed
-- 365,243 anomaly records, identifying these borrowers as pensioners
-- or unemployed applicants with no occupation on record.
-- Leaving as NULL would exclude 31.3% of records from occupation-based
-- segmentation in the EDA script. Reclassifying as 'Not Employed / Unknown'
-- preserves these records in the analysis while accurately representing
-- their employment status.

-- Before: confirm 96,391 null records 
SELECT COUNT(*) AS before_count FROM application_train 
WHERE occupation_type IS NULL;

-- Apply reclassification
UPDATE application_train 
SET occupation_type = 'Not Employed / Unknown' 
WHERE occupation_type IS NULL; 

-- After: confirm 0 null records remain 
SELECT COUNT(*) AS null_after FROM application_train 
WHERE occupation_type IS NULL;

-- Confirm reclassified record count 
SELECT COUNT(*) AS after_count
FROM application_train 
WHERE occupation_type = 'Not Employed / Unknown';


-- 3F. own_car_age: Leave NULL, document structural validity

-- 202,924 records carry no car age value — 66% of the dataset.
-- This missingness is structurally valid, not a data quality failure.
-- NULL maps directly to flag_own_car = N — borrowers who do not own
-- a car have no car age to record by definition. No imputation is
-- appropriate here. Imputing a car age onto a borrower who owns no
-- car would introduce false information into the dataset.
-- No update is performed in this task. The NULL state is confirmed
-- and documented as intentional.

-- Verify null count matchs FLAG_OWN_CAR = N count 
SELECT COUNT(*) AS null_own_car_age FROM application_train
WHERE own_car_age IS NULL; -- Count: 202924

SELECT COUNT(*) AS flag_own_car_n
FROM application_train 
WHERE flag_own_car = 'N'; -- Count: 202924
-- Both counts match - null structure is structurally sound and no action is required 


-- 3G. ext_source_3: Flag, do not impute

-- 60,965 records carry no ext_source_3 value — 19.8% of the dataset.
-- Missingness is non-random: records missing ext_source_3 default at
-- 9.3% versus 7.8% where it is present — a 1.5 percentage point gap
-- that signals the absence of this score is itself a risk indicator.
-- Imputing with median would mask this signal by making missing records
-- appear to have a legitimate external score when they do not.
-- Records are flagged so the EDA script can treat missing ext_source_3
-- as a distinct borrower segment rather than a data gap to be filled.

-- Before: confirm 60,965 null records 
SELECT COUNT(*) AS null_before FROM application_train 
WHERE ext_source_3 IS NULL; 

-- Add flag column 
ALTER TABLE application_train 
ADD flag_missing_ext3 TINYINT(1); 

-- Apply flag
UPDATE application_train 
SET flag_missing_ext3 = CASE
	WHEN ext_source_3 IS NULL THEN 1 ELSE 0 END; 

-- After: confirm 60,965 records flagged 
SELECT COUNT(*) AS flagged_count FROM application_train 
WHERE flag_missing_ext3 = 1; 


-- ============================================================
-- Section 4: Data Transformation and Type Conversion
-- ============================================================
-- Section 4 transforms encoded and raw columns into analytically usable
-- forms across five tasks: converting negative integer day columns into
-- readable year values, adding a binary flag for unemployed and pensioner
-- borrowers, converting a float-encoded integer column to its correct
-- data type, and adding a descriptive risk label column. No records are
-- dropped and all original columns are preserved as an audit trail
-- alongside their derived counterparts. The derived columns produced
-- in Section 4 serve as primary variables in the EDA script for
-- age-based, tenure-based, and risk-tier segmentation.
-- ============================================================

-- 4A. days_birth → age_years

-- days_birth stores age as a negative integer representing days elapsed
-- prior to the application date. Converting to a readable age in years
-- by taking the absolute value and dividing by 365.25 to account for
-- leap years. Original days_birth column is preserved as an audit trail.

-- Preview derived values before commit
SELECT 
	days_birth, 
    ROUND(ABS(days_birth)/365.25,1) AS preview
FROM application_train
LIMIT 10; 

-- Add derived column 
ALTER TABLE application_train 
ADD COLUMN age_years DECIMAL(5,1);

-- Populate derived column
UPDATE application_train
SET age_years = 
	ROUND(ABS(days_birth)/365.25,1);
    
-- Verify: confirming range and no nulls in AGE_YEARS
SELECT MIN(age_years) AS min_age, MAX(age_years) AS max_age, ROUND(AVG(age_years),1) AS avg_age
FROM application_train; 


-- 4B. days_employed → employement_tenure_years

-- days_employed stores employment duration as a negative integer representing
-- days employed prior to the application date, mirroring days_birth encoding.
-- 55,374 records carry a value of 365,243 — a systematic placeholder for
-- pensioners and unemployed borrowers, not a real employment duration.
-- Those records are set to NULL in the derived column. Legitimate records
-- are converted to years using ABS(days_employed) / 365.25 — dividing by
-- 365.25 accounts for leap years across the full range of tenure values.
-- Original days_employed column is preserved as an audit trail.

-- Preview derived values before commit
SELECT 
	days_employed, 
	ROUND(ABS(days_employed)/365.25,1) AS preview
FROM application_train
WHERE days_employed != 365243
LIMIT 10; 

-- Add derived column 
ALTER TABLE application_train
ADD COLUMN employment_tenure_years DECIMAL(5,1); 

-- Populate employment tenure records which != 365243
UPDATE application_train
SET employment_tenure_years = 
	ROUND(ABS(days_employed)/365.25,1)
WHERE days_employed != 365243; 

-- Set anomaly records (= 365243) to NULL 
UPDATE application_train 
SET employment_tenure_years = NULL
WHERE days_employed = 365243;

-- Verify: confirming range and anomaly records are NULL
SELECT 
	MIN(employment_tenure_years) AS min_tenure, 
	MAX(employment_tenure_years) AS max_tenure, 
	ROUND(AVG(employment_tenure_years),1) AS avg_tenure,
    SUM(CASE WHEN employment_tenure_years IS NULL THEN 1 ELSE 0 END) AS null_count
FROM application_train; 


-- 4C. days_employed 365243 → is_unemployed_or_pensioner flag

-- 55,374 records carry days_employed = 365,243 — a systematic placeholder
-- encoding pensioners and unemployed borrowers rather than a real employment
-- duration. This flag makes the anomaly explicitly queryable in the EDA script
-- without requiring a magic number filter on days_employed every time.

-- Before: confirm 55,374 anomaly records
SELECT COUNT(*) AS before_count FROM application_train
WHERE days_employed = 365243; 

-- Add flag column 
ALTER TABLE application_train
ADD COLUMN is_unemployed_or_pensioner TINYINT(1); 

-- Apply flag
UPDATE application_train
SET is_unemployed_or_pensioner = CASE 
	WHEN days_employed = 365243 THEN 1 ELSE 0 END; 
    
-- Verify: confirm 55,374 records flagged
SELECT COUNT(*) AS flagged_count
FROM application_train
WHERE is_unemployed_or_pensioner = 1; 

    
-- 4D. cnt_fam_members: DECIMAL → TINYINT

-- cnt_fam_members was loaded as DECIMAL(5,1) because the source data
-- encoded family member counts as floats (1.0, 2.0, 3.0). Family member
-- count is semantically an integer — no borrower has a fractional family
-- member. Converting to TINYINT now that the imputation in Section 3
-- has resolved the 2 null records.

-- Change cnt_fam_members datatype
ALTER TABLE application_train
MODIFY COLUMN cnt_fam_members TINYINT;

-- Verify: confirm column type changed and no data loss occurred
SELECT 
	MIN(cnt_fam_members) AS min_fam, 
    MAX(cnt_fam_members) AS max_fam, 
    SUM(CASE WHEN cnt_fam_members IS NULL THEN 1 ELSE 0 END) AS null_count 
FROM application_train; 


-- 4E. region_rating_client: add descriptive label column 

-- region_rating_client stores a three-tier numeric risk score: 1, 2, 3.
-- Adding a descriptive label column makes the rating self-explanatory
-- in EDA output without requiring a numeric lookup every time.
-- Default rates confirm the label hierarchy: Low Risk 4.8%,
-- Medium Risk 7.9%, High Risk 11.1%.

-- Before: confirm three-value region rating exists 
SELECT DISTINCT(region_rating_client), COUNT(*) AS before_count FROM application_train 
GROUP BY region_rating_client
ORDER BY region_rating_client; 

-- Add label column
ALTER TABLE application_train
ADD COLUMN region_risk_label VARCHAR(15);

-- Populate region_risk_label column 
UPDATE application_train 
SET region_risk_label = CASE
	WHEN region_rating_client = 1 THEN 'Low Risk'
    WHEN region_rating_client = 2 THEN 'Medium Risk' ELSE 'High Risk' END; 
    
-- Verify: confirm all labels have populated correctly 
SELECT 
	region_risk_label,
    COUNT(*) AS record_count
FROM application_train
GROUP BY region_risk_label; 


-- ============================================================
-- Section 5: Derived Metrics and Final Validation
-- ============================================================
-- Section 5 creates two business-meaningful derived metrics and two
-- borrower segmentation columns, then closes with a post-cleaning
-- validation audit confirming data integrity across the full dataset.
-- The derived metrics produced here are: loan-to-value ratio and
-- debt-to-income ratio. The segmentation columns are: income tier
-- and age band — the primary variables the EDA script will use to
-- segment borrower risk and answer the core analytical question:
-- what combination of borrower characteristics separates low-risk
-- borrowers from high-risk ones. The post-cleaning NULL audit and
-- row count reconciliation confirmed 307,511 records intact with
-- NULL states matching expected values across all seven originally
-- nullable columns.
-- ============================================================

-- 5A. Loan-to-value ratio

-- LTV ratio measures the loan amount relative to the goods price financed.
-- LTV above 1.0 indicates the loan amount exceeds the goods price —
-- common when fees and insurance are rolled into the credit amount.
-- Revolving loans carry no goods price by design and are set to NULL.

-- Before count: confirm revolving loans NULL count 
SELECT COUNT(*) AS before_count FROM application_train 
WHERE name_contract_type = 'Revolving loans';

-- Add column
ALTER TABLE application_train 
ADD COLUMN LTV_RATIO DECIMAL(6,4); 

-- Populate LTV ratio
UPDATE application_train 
SET ltv_ratio = CASE
	WHEN name_contract_type = 'Revolving loans' OR amt_goods_price IS NULL THEN NULL
	ELSE ROUND(amt_credit / amt_goods_price, 4) END;

-- Verify: confirm revolving loans are NULL and range is plausible
SELECT
    MIN(ltv_ratio) AS min_ltv,
    MAX(ltv_ratio) AS max_ltv,
    ROUND(AVG(ltv_ratio), 4) AS avg_ltv,
    SUM(CASE WHEN ltv_ratio IS NULL THEN 1 ELSE 0 END) AS null_count
FROM application_train; 


-- 5B. Debt-to-income ratio

-- DTI ratio measures the proportion of a borrower's annual income consumed
-- by their loan repayment obligation. It is a core underwriting metric —
-- a higher DTI indicates a borrower is more financially stretched relative
-- to their income, increasing default risk. All 307,511 records carry
-- valid annuity and income values following Section 3 imputation - no NULLS
-- expected. Verified DTI Range: min 0.0002, max 1.8760, avg 0.1809.
-- DTI values exceeding 1.0 indicate annuity obligations which surpass annual 
-- income - a significant stress signal examined further in the EDA script. 

-- Add column 
ALTER TABLE application_train
ADD COLUMN DTI_RATIO DECIMAL(6,4); 

-- Populate DTI ratio
UPDATE application_train 
SET dti_ratio = ROUND(amt_annuity / amt_income_total, 4);

-- Verify: confirm range is plausible and no nulls exist 
SELECT 
	MIN(dti_ratio) AS min_dti,
    MAX(dti_ratio) AS max_dti,
    ROUND(AVG(dti_ratio), 4) AS avg_dti,
    SUM(CASE WHEN dti_ratio IS NULL THEN 1 ELSE 0 END) AS null_count
FROM application_train; 


-- 5C. Income tier segmentation 

-- Thresholds align with the 25th ($112,500), 75th ($202,500), and
-- 99th ($472,500) percentiles of the AMT_INCOME_TOTAL distribution
-- profiled in Section 1. Borrowers above the 99th percentile are
-- classified as High — this segment includes the extreme outliers
-- flagged in Section 2D.

-- Add column
ALTER TABLE application_train
ADD COLUMN INCOME_TIER VARCHAR(10);  

-- Populate income tiers 
UPDATE application_train 
SET income_tier = CASE
	WHEN amt_income_total < 112500 THEN 'Low'
    WHEN amt_income_total >= 112500 AND amt_income_total < 202500 THEN 'Mid'
    WHEN amt_income_total >= 202500 AND amt_income_total < 472500 THEN 'Upper-Mid'
    ELSE 'High' END; 

-- Verify: confirm four tiers populated with expected distribution 
SELECT 
	income_tier, COUNT(*) AS record_count
FROM application_train 
GROUP BY income_tier;


-- 5D. Age band segmentation 

-- AGE_YEARS derived in Section 4A is bucketed into five decade bands
-- to enable cohort-level default rate analysis in the EDA script.
-- Age band segmentation is particularly relevant in credit risk —
-- younger borrowers typically carry higher default risk due to shorter
-- credit histories and less stable income.

-- Add column 
ALTER TABLE application_train
ADD COLUMN AGE_BAND VARCHAR(10); 

-- Populate age bands
UPDATE application_train 
SET age_band = CASE
	WHEN age_years < 30 THEN '20s'
    WHEN age_years >= 30 AND age_years < 40 THEN '30s'
    WHEN age_years >= 40 AND age_years < 50 THEN '40s'
    WHEN age_years >= 50 AND age_years < 60 THEN '50s'
    ELSE '60 plus' END; 
    
-- Verify: confirm five bands populated with counts summing to 307,511
SELECT 
	age_band, COUNT(*) AS record_count 
FROM application_train 
GROUP BY age_band; 


-- 5E. Post-cleaning NULL audit
SELECT 
	SUM(CASE WHEN amt_annuity IS NULL THEN 1 ELSE 0 END) AS null_amt_annuity, -- NULL amt_annuity: 0 
    SUM(CASE WHEN amt_goods_price IS NULL THEN 1 ELSE 0 END) AS null_amt_goods_price, -- NULL amt_goods_price: 278 - Expected and intentional. Columns were flagged and imputed by design. 
    SUM(CASE WHEN cnt_fam_members IS NULL THEN 1 ELSE 0 END) AS null_cnt_fam_members, -- NULL cnt_fam_members: 0
    SUM(CASE WHEN own_car_age IS NULL THEN 1 ELSE 0 END) AS null_own_car_age,  -- NULL own_car_age: 202924
    SUM(CASE WHEN occupation_type IS NULL THEN 1 ELSE 0 END) AS null_occupation_type, -- NULL occupation_type: 0
    SUM(CASE WHEN ext_source_2 IS NULL THEN 1 ELSE 0 END) AS null_ext_source_2, -- NULL ext_source_2: 0
    SUM(CASE WHEN ext_source_3 IS NULL THEN 1 ELSE 0 END) AS null_ext_source_3 -- NULL ext_source_3: 60965 - Expected and intentional. Columns were flagged and imputed by design. 
FROM application_train; 


-- 5F. Row count reconciliation
SELECT COUNT(*) AS total_records FROM application_train; -- 307,511 records have been verified 