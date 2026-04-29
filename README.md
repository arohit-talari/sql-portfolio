<h1 align="left">SQL Portfolio</h1>

Welcome to my SQL portfolio! This repository showcases my technical capabilities across two focus areas — **data cleaning and transformation**, and **exploratory data analysis (EDA)** — applied to real-world business problems with decisions that depend on them.

Before any project begins, my approach remains the same: the question comes first. What is the data being asked to answer, and for whom? The technical work — cleaning, transformation, analysis — follows from that. With the question established and the data structured to answer it, every decision made along the way is documented with the reasoning behind it.

Each project contains the original dataset, a cleaning script, and an EDA script — fully annotated at every step.

<h2 align="left">Projects</h2>

<h3 align="left">Home Credit Group - Borrower Risk Profiling</h3>

Home Credit Group extends loans to underbanked borrowers — a population largely excluded from traditional credit markets due to limited or nonexistent credit histories. Without conventional credit scores, the business faces a fundamental challenge: determining which borrower characteristics reliably predict who will repay and who won't. At 122 columns across 307,511 loan applications, the data had to be understood before it could be analyzed — each variable interpreted in the context of Home Credit's lending model, scoped to 25 columns, and cleaned before a single exploratory query was written. The analysis identified a specific borrower profile where default risk concentrates — and quantified exactly how far above the portfolio benchmark it sits.

| | |
|---|---|
| **Domain** | Finance · Credit Risk |
| **Tools** | MySQL |
| **SQL Skills** | Data Cleaning · NULL Handling · Conditional Logic · Uni/Bivariate Analysis · Threshold Analysis · Risk Segmentation · EDA |
| **Dataset** | 1 table · 307,511 loan applications · 25 columns retained |

[Project README](https://github.com/arohit-talari/home-credit-default-risk) **·** [Data Cleaning Script](https://github.com/arohit-talari/home-credit-default-risk/blob/main/scripts/home_credit_data_cleaning.sql) **·** [EDA Script](https://github.com/arohit-talari/home-credit-default-risk/blob/main/scripts/home_credit_eda.sql)

<h3 align="left">Olist — Marketplace Risk Analysis</h3>

Olist is a Brazilian e-commerce platform connecting small and medium-sized merchants to major online marketplaces — serving as the intermediary between independent sellers and customers across Brazil for order fulfillment, payment processing, and customer review collection across 3,095 sellers and 99,441 orders spanning 2016 to 2018. Olist's business model depends entirely on seller retention and customer trust — when deliveries fail and satisfaction drops, sellers lose repeat customers they cannot afford to lose, customers abandon the platform for direct alternatives, and Olist risks losing the marketplace commission revenue that funds its own operation. The core analytical question: which combination of seller behavior, product category, and delivery patterns drives the highest concentration of late deliveries, low customer satisfaction, and revenue risk? No single table could answer it — the data required to address seller behavior, product performance, delivery outcomes, and customer satisfaction lived across eight relational tables, each requiring individual cleaning and dependency-ordered loading before a single JOIN could be written. The analysis identified a concentrated seller segment whose delivery failures put a disproportionate share of marketplace revenue at risk.

| | |
|---|---|
| **Domain** | E-Commerce · Marketplace Operations |
| **Tools** | MySQL |
| **SQL Skills** | Data Cleaning · Relational Joins · Subquery Design · Dependency Loading · Conditional Logic · Bivariate Analysis · EDA  |
| **Dataset** | 8 tables · 99,441 orders · 35 columns retained |

[Project README](https://github.com/arohit-talari/olist-ecommerce-analysis) **·** [Data Cleaning Script](https://github.com/arohit-talari/olist-ecommerce-analysis/blob/main/scripts/olist_data_cleaning.sql) **·** [EDA Script](https://github.com/arohit-talari/olist-ecommerce-analysis/blob/main/scripts/olist_eda.sql)

