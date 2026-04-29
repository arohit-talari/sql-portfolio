

-- ============================================================
-- Home Credit Risk — Exploratory Data Analysis Script
-- ============================================================
-- This script performs exploratory data analysis on the data 
-- prepared in the companion Home Credit Risk cleaning script - 
-- 99,441 orders from Olist, a financial 
-- institution serving underbanked borrowers. The analysis is built 
-- to answer one question: what combination of borrower characteristics 
-- separates low-risk borrowers from high-risk ones. The script moves
-- sequentially from univariate profiling through bivariate analysis, 
-- financial ratio examination, and composite risk segmentation - each
-- section building on the last toward a consolidated finding. All derived
-- columns, segmentation variables, and flag columns referenced throughout 
-- this script were created in the companion cleaning script.

-- Author: Arohit Talari       
-- Dataset: application_train.csv     
-- Source: https://www.kaggle.com/competitions/home-credit-default-risk/data        
-- MySQL Version: 9.5.0
-- ============================================================


-- ============================================================
-- Section 1: Univariate Analysis
-- ============================================================
-- Section 1 examines each variable in isolation to establish the
-- baseline default rate profile of the borrower population before
-- any cross-variable analysis begins. The overall default rate of
-- 8.07% — established in the cleaning script — serves as the
-- benchmark for every comparison in this section. Variables are
-- examined in order of analytical significance, from loan contract
-- type through demographic characteristics, segmentation variables,
-- and geographic risk rating. Findings from this section directly
-- motivate the bivariate and ratio analysis in Sections 2 and 3.
-- ============================================================

-- 1A. Default rate by contract type

-- Cash loans represent 90.5% of the portfolio's contract type — 
-- 278,232 records against 29,279 revolving loans. Cash loans default
-- at 8.3% versus revolving loans at 5.5% — a 2.8 percentage point gap
-- that signals meaningfully different risk profiles across contract types. 
-- The portfolio's heavy concentration in cash loans creates concentration
-- risk and obscures true risk exposure across products.

SELECT 
	name_contract_type AS contract_type, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY name_contract_type;

-- 1B. Default rate by gender 

-- Female borrowers dominate the portfolio at 65.9% of records (202,448)
-- against 34.1% male (105,059). Male borrowers default at 10.14% versus
-- 7.00% for female borrowers - a 3.14 percentage point gap. The portfolio's
-- female-heavy composition partially offsets male default risk at the blended 
-- level, contributing to the 8.07% overall average. 4 XNA gender records 
-- resolved in the section 2A of the cleaning script are excluded from this analysis.

SELECT 
	code_gender AS gender, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
WHERE code_gender IS NOT NULL
GROUP BY code_gender;

-- 1C. Default rate by education level

-- Among demographic variables with statistically reliable segment volumes,
-- education level produces the widest default rate spread in the dataset -
-- from 10.93% at lower secondary to 1.83% at academic degree level, a nearly
-- sixfold difference. Lower secondary carries the highest risk at 10.93% but 
-- is limited to 3,816 records — its portfolio impact is contained by low volume.
-- Secondary / secondary special is the most consequential segment: 218,391 records
-- at 8.94% — 71% of the entire borrower population defaulting above the 8.07% benchmark.
-- Higher education at 5.36% across 74,863 records is the strongest high-volume 
-- risk mitigant in the portfolio. Academic degree at 1.83% across only 164 records
-- is statistically notable but too small to be portfolio-meaningful.

SELECT 
	name_education_type AS education, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY name_education_type
ORDER BY default_rate DESC;

-- 1D. Default rate by income type 

-- Maternity leave (40.00%, 5 records), Businessman (0.00%, 10 records),
-- and Student (0.00%, 18 records) are statistically unreliable due to
-- insufficient volume and are excluded from analytical conclusions.
-- Unemployed borrowers carry a 36.36% default rate across 22 records —
-- portfolio impact is limited by volume, but the rate is the strongest
-- individual risk signal in the data among reliable segments.
-- Working borrowers are the most consequential segment: 9.59% default
-- rate across 158,774 records — 51.6% of the entire borrower population
-- defaulting above the 8.07% benchmark. Pensioner (5.39%, 55,362) and
-- State servant (5.76%, 21,703) are the strongest low-risk stable
-- segments, both with meaningful volume and default rates well below average.

SELECT 
	name_income_type AS income_type, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY name_income_type
ORDER BY default_rate DESC;

-- 1E. Default rate by housing type 

-- Rented apartment (12.31%, 4,881) and living with parents (11.70%, 14,840)
-- carry the two highest default rates — both segments lack stable
-- long-term housing, which correlates with financial instability and
-- elevated default risk. With-parents borrowers carry 3x the volume
-- of renters, giving them greater portfolio impact despite a marginally
-- lower rate. Co-op apartment (7.93%, 1,122) and office apartment
-- (6.57%, 2,617) carry limited volume and conclusions from these
-- segments should be treated with caution. House / apartment dominates
-- the portfolio at 272,868 records — 88.7% of borrowers — defaulting
-- at 7.80%, just below the 8.07% benchmark, anchoring the overall rate.
-- Borrowers without stable long-term housing default 4 to 5 percentage
-- points above average — a signal with direct implications for housing
-- status weighting in credit underwriting decisions.

SELECT 
	name_housing_type AS housing, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY name_housing_type
ORDER BY default_rate DESC;

-- 1F. Default rate by age band 

-- Default risk follows a clear inverse relationship with age — younger
-- borrowers carry the highest risk and it declines steadily with each
-- decade. Borrowers in their 20s carry the highest default rate at
-- 11.47% across 44,738 records — 3.31 percentage points above the
-- 8.07% benchmark. The 30s cohort remains elevated at 9.58% across
-- 82,390 records — the largest age segment by volume. Risk drops
-- below the benchmark at 40s (7.66%, 76,602) and continues declining
-- through 50s (6.14%, 68,116) and 60 plus (4.92%, 35,665). The pattern
-- is linear and consistent — each decade carries a lower default rate
-- than the last, confirming that age is a reliable proxy for financial
-- stability. 

SELECT 
	age_band, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY age_band
ORDER BY default_rate DESC;

-- 1G. Default rate by income tier 

-- The relationship between income and default risk is not linear —
-- Mid income borrowers carry the highest default rate at 8.55% across
-- 150,073 records, marginally above Low income borrowers at 8.23%
-- across 69,559 records. Upper-Mid borrowers default at 7.20% across
-- 84,785 records. High income borrowers carry the lowest default rate
-- at 5.43% but represent only 3,094 records — 1.0% of the portfolio.
-- The absence of a clean inverse relationship between income and default
-- risk suggests income level alone is not a reliable standalone predictor
-- of default — financial behavior, debt obligations, and employment
-- stability interact with income in ways this univariate view cannot
-- capture. This finding motivates the bivariate and ratio analysis in
-- Sections 2 and 3.

SELECT 
	income_tier, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY income_tier
ORDER BY default_rate DESC;

-- 1H. Default rate by region risk label 

-- The three-tier regional risk rating produces the cleanest default rate
-- scaling of any variable examined in Section 1. High Risk regions carry
-- an 11.10% default rate across 48,330 records, Medium Risk regions sit
-- at 7.89% across 226,984 records — the dominant segment at 73.8% of
-- the portfolio — and Low Risk regions carry 4.82% across 32,197 records.
-- The spread from 4.82% to 11.10% across three tiers is a 6.28 percentage
-- point range. This confirms region_rating_client as one of the most reliable
-- single-variable risk signals — geographic risk concentration is a meaningful
-- and consistent default predictor. Of all variables examined in Section 1, 
-- region_rating_client requires no cross-variable context to function as a 
-- reliable risk screening input — its three-tier scaling is consistent
-- enough to stand alone in an underwriting decision.

SELECT 
	region_risk_label AS region_risk, 
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY region_risk_label
ORDER BY default_rate DESC;


-- ============================================================
-- Section 2: Bivariate Analysis
-- ============================================================
-- Section 2 crosses two variables simultaneously to surface patterns
-- that univariate analysis cannot reveal. Each query combines a
-- demographic or behavioral variable with default rate and volume
-- to identify where risk concentrations emerge at the intersection
-- of borrower characteristics. The non-linear income tier finding
-- from Section 1 — where Mid income borrowers defaulted at a higher
-- rate than Low income borrowers — specifically motivated the
-- cross-variable queries in this section, as income alone proved
-- insufficient to explain default risk distribution.
-- ============================================================


-- 2A. Education level by income 

-- Crossing a borrower's education with income tier confirms that education 
-- level dominates default risk regardless of income — lower secondary
-- borrowers carry the highest default rates across every income tier
-- they appear in, peaking at 12.45% in Mid income (1,751 records).
-- Higher education borrowers consistently sit below the 8.07% benchmark
-- across all four income tiers — from 5.93% at Low to 3.72% at High —
-- confirming that education level is a more reliable default predictor
-- than income tier alone. The non-linear income finding from Section 1
-- is explained here: Mid income borrowers carry disproportionate
-- exposure to lower secondary and secondary / secondary special
-- education segments, which pulls their blended default rate above
-- Low income borrowers despite higher earnings. 

SELECT 
	name_education_type AS education, 
    income_tier AS income_tier,
	ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY name_education_type, income_tier
ORDER BY default_rate DESC;


-- 2B. Age band by contract type

-- The age effect identified in Section 1 holds consistently across
-- both contract types — younger borrowers carry higher default rates
-- regardless of contract type. Cash loan borrowers in their 20s
-- carry the highest default rate in this cross at 12.07% across
-- 38,043 records. Revolving loan borrowers in their 20s default at
-- 8.07% — exactly at the portfolio benchmark — suggesting revolving
-- credit partially mitigates age-related default risk, likely due
-- to the self-regulating nature of revolving credit limits.
-- Across every age band, cash loans carry a higher default rate than
-- revolving loans — the contract effect and age effect are additive,
-- not offsetting.

SELECT 
	age_band AS age, 
    name_contract_type AS contract,
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train
GROUP BY age_band, name_contract_type
ORDER BY default_rate DESC; 

-- 2C. Housing type by employment status

-- Crossing housing type with employment status reveals that housing
-- instability drives default risk independently of employment status.
-- Rented apartment borrowers who are actively employed (flag = 0)
-- default at 12.55% — higher than any unemployed or pensioner housing
-- segment in this cross. With parents borrowers who are employed
-- default at 11.80%. This confirms that housing instability is a
-- standalone default risk driver, not simply a proxy for unemployment.
-- Unemployed and pensioner borrowers (flag = 1) show materially lower
-- default rates across all housing types — reflecting that this segment
-- is predominantly pensioners with stable income rather than
-- unemployed borrowers, as confirmed by the days_employed anomaly
-- analysis in the Section 3E of the cleaning script.

SELECT 
	name_housing_type AS housing,
    is_unemployed_or_pensioner,
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train 
GROUP BY name_housing_type, is_unemployed_or_pensioner
ORDER BY default_rate DESC;

-- 2D. Income tier by age band 

-- This cross produces the most granular risk concentration view in
-- Section 2. Low income borrowers in their 20s carry the highest
-- default rate at 12.67% across 9,874 records, followed by Mid income
-- borrowers in their 20s at 11.89% across 24,202 records. The age
-- effect dominates across all income tiers — within every income tier,
-- default rates decline steadily with each decade. High income
-- borrowers across all age bands sit below the 8.07% benchmark,
-- confirming that High income is the only tier where income
-- meaningfully suppresses default risk regardless of age.
-- The highest risk concentration is Low and Mid income borrowers
-- under 40, a combination which accounts for a disproportionate share
-- of portfolio default exposure. This combination — Low and Mid income
-- borrowers under 40 — anchors the high-risk borrower profile definition
-- constructed in Section 4, where it is combined with housing stability 
-- and debt burden to produce the composite risk segmentation.

SELECT 
	income_tier, 
    age_band AS age,
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train 
GROUP BY income_tier, age_band
ORDER BY default_rate DESC;

-- 2E. Education level by employment status 

-- Employment status does not mitigate the education effect — lower
-- secondary borrowers who are actively employed (flag = 0) carry the
-- highest default rate in this cross at 13.77% across 2,287 records.
-- Secondary / secondary special employed borrowers default at 9.81%
-- across 173,286 records — the most consequential segment by volume.
-- Unemployed and pensioner borrowers (flag = 1) default at lower rates
-- across every education tier, again reflecting the pensioner
-- composition of the flag = 1 segment. Higher education borrowers
-- carry below-benchmark default rates in both employment segments —
-- 5.50% employed and 4.15% unemployed or pensioner — confirming
-- education level as a consistent default suppressor regardless
-- of employment status.

SELECT 
	name_education_type AS education, 
    is_unemployed_or_pensioner,
	ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train 
GROUP BY name_education_type, is_unemployed_or_pensioner
ORDER BY default_rate DESC;

-- 2F. Region risk by contract type 

-- The clean regional risk signal from Section 1 holds across both
-- contract types without exception. High Risk cash loans carry the
-- highest default rate at 11.50% across 43,997 records. Low Risk
-- revolving loans carry the lowest at 2.67% across 3,789 records.
-- Within every region risk tier, cash loans default at a higher rate
-- than revolving loans — the regional risk effect and contract effect
-- are additive and consistent. The regional rating system performs
-- as a reliable risk differentiator regardless of contract type,
-- confirming its value as a standalone underwriting input.

SELECT 
	region_risk_label AS region_risk, 
    name_contract_type AS contract_type,
    ROUND(AVG(target) * 100,2) AS default_rate, 
    COUNT(*) AS volume
FROM application_train 
GROUP BY region_risk_label, name_contract_type
ORDER BY default_rate DESC;


-- ============================================================
-- Section 3: Financial Ratio Analysis
-- ============================================================
-- Section 3 examines two derived financial ratios created in the
-- cleaning script — DTI (debt-to-income) and LTV (loan-to-value).
-- Sections 1 and 2 identified who defaults across demographic and
-- behavioral segments — Section 3 examines the financial mechanics
-- of how they default by analyzing debt burden and financing structure
-- at the individual borrower level. The threshold analysis in this
-- section is designed to identify the DTI and LTV values at which
-- default risk accelerates meaningfully above the 8.07% benchmark.
-- ============================================================

-- 3A. DTI ratio distribution 

-- Defaulted borrowers carry a marginally higher average DTI at 0.1855
-- versus 0.1805 for non-defaulted borrowers — a 0.50 percentage point
-- gap. The gap is narrow enough that DTI alone is not a strong standalone
-- default predictor at the average level, irrespective of the fact 
-- that higher debt burden correlates with a higher default risk. 
-- The max DTI of 1.8760 among defaulted borrowers versus 1.5706 among
-- non-defaulted borrowers is more telling — extreme debt obligation
-- is concentrated in the defaulted population. DTI's predictive value
-- emerges at the threshold level examined in block 3C, not the average.

SELECT 
	target,
	ROUND(MIN(dti_ratio),4) AS min_dti,
    ROUND(MAX(dti_ratio),4) AS max_dti,
    ROUND(AVG(dti_ratio),4) AS avg_dti
FROM application_train
GROUP BY target
ORDER BY avg_dti DESC; 

-- 3B. DTI ratio by income 

-- DTI distribution by income tier directly explains the non-linear
-- default rate pattern identified in Section 1. Low income borrowers
-- carry the highest average DTI at 0.2369 — nearly a quarter of their
-- annual income consumed by loan repayment obligations — which explains
-- why Low income borrowers default at rates comparable to Mid income
-- despite earning less. Mid income borrowers average 0.1814 DTI while
-- Upper-Mid borrowers average 0.1379 — a declining pattern consistent
-- with greater financial capacity at higher income levels. High income
-- borrowers carry the lowest average DTI at 0.0789 and a max of
-- 0.3950 — confirming that High income borrowers are the
-- only tier where debt burden is consistently contained relative to
-- income. Income tier evaluated without DTI context produces an
-- incomplete and potentially misleading risk picture — the two
-- variables should be examined together to accurately represent a
-- borrower's financial position relative to their debt obligations.

SELECT 
	income_tier, 
    ROUND(MIN(dti_ratio),4) AS min_dti,
    ROUND(MAX(dti_ratio),4) AS max_dti,
    ROUND(AVG(dti_ratio),4) AS avg_dti
FROM application_train
GROUP BY income_tier
ORDER BY avg_dti DESC; 

-- 3C. DTI ratio threshold analysis

-- DTI threshold analysis reveals a non-linear relationship between
-- debt burden and default risk. Borrowers with DTI between 0.1 and 0.2
-- carry the highest volume at 147,883 records and default at 8.01% —
-- just below the 8.07% benchmark. The 0.2 to 0.3 band carries the
-- highest default rate at 8.76% across 73,972 records — this is the
-- threshold at which debt burden begins to meaningfully elevate default
-- risk above the portfolio average. Borrowers under 0.1 DTI default at
-- 7.26% — the lowest rate — confirming that low debt obligation relative
-- to income is a meaningful risk mitigant. The Above 0.4 band defaults
-- at 8.27% across only 7,941 records, indicating extreme DTI does not produce
-- proportionally extreme default rates, suggesting other factors
-- dominate at the highest debt burden levels. DTI above 0.20 is the
-- actionable threshold for elevated underwriting scrutiny as applied in 
-- Section 4 to high-risk borrowers.

SELECT
	CASE 
    WHEN dti_ratio < 0.1 THEN 'Under 0.1'
    WHEN dti_ratio < 0.2 THEN '0.1 to 0.2'
    WHEN dti_ratio < 0.3 THEN '0.2 to 0.3'
    WHEN dti_ratio < 0.4 THEN '0.3 to 0.4'
    ELSE 'Above 0.4' END AS dti_band,
	ROUND(AVG(target) * 100,2) AS default_rate,
	COUNT(*) AS volume
FROM application_train
GROUP BY dti_band
ORDER BY default_rate DESC;

-- 3D. LTV ratio by default outcome

-- Defaulted borrowers carry an average LTV of 1.1624 versus 1.1335 for
-- non-defaulted borrowers — a 0.03 difference. Like DTI at the average
-- level, LTV alone is not a strong standalone default predictor.
-- The marginal difference suggests that financing level relative to
-- goods price does not independently drive default — borrower financial
-- capacity and employment stability are stronger determinants.
-- LTV's analytical value is better examined in combination with DTI
-- as demonstrated in block 3E.

SELECT
	target, 
    ROUND(AVG(ltv_ratio), 4) AS avg_ltv,
    COUNT(*) AS volume
FROM application_train 
WHERE ltv_ratio IS NOT NULL
GROUP BY target;

-- 3E. Combined DTI and LTV risk view 

-- The combination of High DTI and High LTV produces the highest default
-- rate in this cross at 12.66% across 5,127 records — confirming that
-- these two ratios compound when present together. Low DTI with Low LTV
-- produces the lowest default rate at 7.33% across 187,299 records —
-- the largest and safest segment in the portfolio. Critically, High DTI
-- with Low LTV defaults at only 7.27% across 26,308 records — matching
-- the safest segment — which reveals that high debt burden alone does
-- not elevate default risk when financing is conservative. High LTV
-- without High DTI defaults at 9.61% across 88,777 records, sitting
-- above the benchmark but well below the High DTI / High LTV
-- combination. The key takeaway is this: neither ratio alone produces
-- the risk concentration that the combination does. A borrower carrying
-- both High DTI and High LTV is the clearest financial risk profile in the data.

SELECT 
	CASE
		WHEN dti_ratio < 0.3 THEN 'Low DTI' ELSE 'High DTI' END AS dti_band,
	CASE
		WHEN ltv_ratio < 1.2 THEN 'Low LTV' ELSE 'High LTV' END AS ltv_band,
	ROUND(AVG(target) * 100,2) AS default_rate,
    COUNT(*) AS volume 
FROM application_train
GROUP BY dti_band, ltv_band
ORDER BY default_rate DESC; 


-- ============================================================
-- Section 4: Borrower Risk Segmentation
-- ============================================================
-- Section 4 combines the strongest risk signals identified across
-- Sections 1 through 3 to build composite borrower risk profiles,
-- directly answering the core analytical question: what combination
-- of borrower characteristics separates low-risk borrowers from
-- high-risk ones. The bivariate finding from Section 2 — that Low
-- and Mid income borrowers under 40 carry the highest default rate
-- concentration in the dataset — anchors the high-risk profile
-- definition used throughout this section. The composite risk
-- comparison in block 4C quantifies the default rate spread between
-- the highest and lowest risk borrower profiles, producing the
-- headline finding of the entire project.
-- ============================================================

-- 4A. High-risk borrower profile

-- Borrowers combining all four high-risk signals — age band 20s or 30s,
-- Low or Mid income, unstable housing, and DTI above 0.20 — default at
-- 14.30% across 4,533 records. This is 6.23 percentage points above the
-- 8.07% portfolio benchmark — a 77% elevation in default risk relative
-- to the average borrower. Average DTI within this segment is 0.2778,
-- confirming that debt burden is a defining characteristic of the
-- high-risk profile. This segment represents 1.5% of the portfolio
-- but carries a disproportionate share of default exposure.

SELECT 
	ROUND(AVG(target) * 100, 2) AS default_rate,
    ROUND(AVG(dti_ratio), 4) AS avg_dti,
    COUNT(*) AS volume
FROM application_train 
WHERE age_band IN ('20s', '30s')
AND income_tier IN ('Low', 'Mid')
AND name_housing_type IN ('Rented apartment', 'With parents')
AND dti_ratio > 0.2; 

-- 4B. Low-risk borrower profile

-- Borrowers combining all four low-risk signals — age band 50s or 60
-- plus, Upper-Mid or High income, house or apartment housing, and DTI
-- below 0.10 — default at 5.42% across 553 records. This is 2.65
-- percentage points below the 8.07% benchmark. Average DTI of 0.0631
-- confirms minimal debt burden relative to income. The small volume
-- of 553 records reflects how rare the combination of all four
-- favorable signals are in this borrower population — low-risk
-- borrowers are a narrow segment of the Home Credit portfolio.

SELECT 
	ROUND(AVG(target) * 100,2) AS default_rate,
    ROUND(AVG(dti_ratio), 4) AS avg_dti,
	COUNT(*) AS volume
FROM application_train 
WHERE age_band IN ('50s', '60 plus')
AND income_tier IN ('Upper-Mid', 'High') 
AND name_housing_type = 'House / apartment'
AND dti_ratio < 0.1; 

-- 4C. Risk profile comparison

-- The three-segment risk classification consolidates the full analysis
-- into a single view. High Risk borrowers default at 14.30% with an
-- average DTI of 0.2778 and LTV of 1.1398 across 4,533 records.
-- Standard borrowers — the vast majority at 302,425 records — default
-- at 7.98%, just below the 8.07% benchmark, with average DTI of 0.1797
-- and LTV of 1.1359. Low Risk borrowers default at 5.42% with the
-- lowest DTI at 0.0631 and LTV at 1.1181 across 553 records.
-- The default rate spread from 5.42% to 14.30% across the three
-- profiles — a 8.88 percentage point range — directly answers the
-- core analytical question: the combination of age, income, housing
-- stability, and debt burden produces a measurable and meaningful
-- separation between low-risk and high-risk borrowers in this portfolio
-- as consolidated in the Section 5 summary findings.

SELECT 
	CASE
		WHEN age_band IN ('20s', '30s') 
        AND income_tier IN ('Low', 'Mid') 
        AND name_housing_type IN ('Rented apartment', 'With parents')
        AND dti_ratio > 0.2 
	THEN 'High Risk'
		WHEN age_band IN ('50s', '60 plus') 
        AND income_tier IN ('Upper-Mid', 'High') 
        AND name_housing_type = 'House / apartment'
        AND dti_ratio < 0.1 
	THEN 'Low Risk'
    ELSE 'Standard' END AS risk_profile,
    ROUND(AVG(target) * 100,2) AS default_rate, 
    ROUND(AVG(dti_ratio),4) AS avg_dti,
    ROUND(AVG(ltv_ratio),4) AS avg_ltv,
    COUNT(*) AS volume
FROM application_train
GROUP BY risk_profile 
ORDER BY default_rate DESC;

-- 4D. Employment anomaly risk impact

-- Actively employed borrowers (flag = 0) default at 8.66% across
-- 252,137 records — above the 8.07% benchmark. Unemployed and
-- pensioner borrowers (flag = 1) default at 5.40% across 55,374
-- records — well below the benchmark. This counterintuitive result
-- is explained by the composition of the flag = 1 segment: the
-- 365,243 anomaly population is predominantly pensioners with stable
-- fixed income rather than unemployed borrowers, as confirmed by the
-- name_income_type breakdown in Section 1. The cleaning script's
-- decision to flag rather than drop these records preserved a finding
-- that would have been lost had the anomaly records been excluded.
-- This result reinforces the Section 2C finding that employment status
-- assumptions require nuanced interpretation in this portfolio.

SELECT 
	is_unemployed_or_pensioner,
	ROUND(AVG(target) * 100,2) AS default_rate,
	COUNT(*) AS volume
FROM application_train 
GROUP BY is_unemployed_or_pensioner
ORDER BY default_rate DESC;

-- 4E. Top 5 highest risk organization types

-- With a 500-record minimum applied to exclude statistically unreliable
-- segments, Transport type 3 holds as the highest-risk employer
-- category at 15.75% default rate across 1,187 records — nearly double
-- the 8.07% portfolio benchmark. Restaurant (11.71%, 1,811) and
-- Construction (11.68%, 6,721) follow as the next highest risk
-- employer categories — both industries characterized by irregular
-- income, physical labor, and limited employment security. Industry
-- type 1 (11.07%, 1,039) and Industry type 3 (10.62%, 3,278) round
-- out the top five. The pattern confirms that employer industry type
-- is a meaningful default risk signal — borrowers in transient and
-- physically demanding industries default at materially higher rates
-- than the portfolio average. Employer industry type warrants inclusion
-- as a standalone screening variable in credit underwriting decisions.

SELECT 
	organization_type,
	ROUND(AVG(target) * 100,2) AS default_rate,
    COUNT(*) AS volume
FROM application_train
GROUP BY organization_type
HAVING COUNT(organization_type) > 500
ORDER BY default_rate DESC
LIMIT 5;


-- ============================================================
-- Section 5: Summary Findings 
-- ============================================================
-- Section 5 consolidates the most analytically significant findings
-- from Sections 1 through 4 into a set of actionable conclusions
-- tailored for a credit risk audience.
--
-- Finding 1: The core analytical question answered
-- Borrowers under 40, clustered into Low or Mid income, living in unstable
-- housing, and carrying a DTI above 0.20 default at 14.30% — 77%
-- above the 8.07% portfolio benchmark. Borrowers combining the
-- opposite profile default at 5.42%. The 8.88 percentage point
-- spread directly answers what separates high-risk from low-risk
-- borrowers in this portfolio.
--
-- Finding 2: Education level is the strongest demographic signal
-- Default rates range from 1.83% at the academic degree level to
-- 10.93% at lower secondary — a nearly sixfold difference. Secondary
-- and secondary special borrowers default at 8.94% across 218,391
-- records — the most consequential risk segment by volume given their
-- combination of above-benchmark default rate and dominant portfolio share.
--
-- Finding 3: Age and region rating are the two most reliable
-- standalone risk indicators in the data
-- Both variables produce linear, consistent, no-exception default rate
-- scaling across every segment. Age declines steadily from 11.47%
-- in the 20s cohort (44,738 records) to 4.92% among 60 plus borrowers
-- (35,665 records). Regional risk tiers scale cleanly from 4.82%
-- in Low Risk regions (32,197 records) to 11.10% in High Risk regions
-- (48,330 records) — a 6.28 percentage point spread across three tiers. 
-- When assessing a new borrower's risk level in isolation, these are the two
-- variables with the most predictive consistency.
--
-- Finding 4: DTI above 0.20 is the actionable financial threshold
-- Default risk accelerates meaningfully once a borrower's DTI exceeds
-- 0.20. The compounding effect confirmed in the combined DTI and LTV
-- analysis — High DTI with High LTV produces a 12.66% default rate (5,127
-- records) versus 7.33% (187,299 records) for Low DTI with Low LTV 
-- establishes DTI as the most actionable financial screening variable.
--
-- Finding 5: Income tier alone is an unreliable standalone predictor
-- Mid and Low income borrowers default at nearly identical rates —
-- 8.55% and 8.23% respectively — a 0.32 percentage point gap that is
-- not meaningful at the portfolio level. High income is the only tier
-- where income reliably suppresses default risk, at 5.43%. Below that
-- threshold, debt burden, age, housing stability, and employment
-- interact with income in ways that make income tier an unreliable
-- predictor in either direction. Low income borrowers carry the highest
-- average DTI in the dataset at 0.2369 — indicating these borrowers
-- are more financially stretched relative to their income than their 
-- earnings tier implies. This explains why they default comparably to
-- Mid income borrowers despite earning less. Income without debt burden
-- context produces incomplete risk conclusions.
--
-- Finding 6: Employment status requires a nuanced interpretation
-- Employed renters default at 12.55% — higher than unemployed and
-- pensioner borrowers across every housing type. Unemployed and
-- pensioner borrowers flag at 5.40%, well below the 8.07% benchmark,
-- because the segment is predominantly pensioners with stable fixed
-- income rather than unemployed borrowers with no income. Housing
-- instability is a stronger default driver than employment status
-- in this portfolio — a finding that directly challenges conventional
-- underwriting assumptions.
--
-- Finding 7: Employer industry type is a meaningful and underutilized
-- risk signal
-- Among organization types with more than 500 records, Transport type 3
-- carries the highest default rate at 15.75% across 1,187 records —
-- nearly double the portfolio benchmark. Restaurant (11.71%), and
-- Construction (11.68%) follow, both industries characterized by
-- irregular income and limited employment security. Borrowers in
-- transient and physically demanding industries default at materially
-- higher rates — employer industry type warrants inclusion as a standalone
-- screening variable in credit underwriting decisions.
-- ============================================================

