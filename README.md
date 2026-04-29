<h1 align="left">SQL Portfolio</h1>

Welcome to my SQL portfolio! This repository showcases my technical capabilities across two focus areas — **data cleaning and transformation**, and **exploratory data analysis (EDA)** — applied to real-world business problems with decisions that depend on them.

Before any project begins, my approach remains the same: the question comes first. What is the data being asked to answer, and for whom? The technical work — cleaning, transformation, analysis — follows from that. With the question established and the data structured to answer it, every decision made along the way is documented with the reasoning behind it.

Each project contains the original dataset, a cleaning script, and an EDA script — fully annotated at every step.

<h2 align="left">Projects</h2>

<h3 align="left">Home Credit Group - Borrower Risk Profiling</h3>

Home Credit Group extends loans to underbanked borrowers — a population largely excluded from traditional credit markets due to limited or nonexistent credit histories. Without conventional credit scores, identifying which borrower characteristics reliably predict repayment behavior is the core underwriting challenge. At 122 columns, the dataset had to be understood before it could be analyzed — each variable interpreted in the context of Home Credit's lending model, scoped to 25 columns, and cleaned before a single exploratory query was written. The analysis produced a defined high-risk borrower profile — isolating the demographic, financial, and stability factors that separate high-risk borrowers from low-risk ones in this portfolio.

| | |
|---|---|
| **Domain** | Finance · Credit Risk |
| **Tools** | MySQL |
| **SQL Skills** | Data Cleaning · Data Profiling · NULL Handling · Conditional Logic · Uni/Bivariate Analysis · Threshold Analysis · Composite Segmentation · EDA |
| **Dataset** | 307,511 rows · 25 columns |

[View Project README](https://github.com/arohit-talari/home-credit-default-risk) **·** [View Data Cleaning Script](https://github.com/arohit-talari/home-credit-default-risk/blob/main/scripts/home_credit_data_cleaning.sql) **·** [View EDA Script](https://github.com/arohit-talari/home-credit-default-risk/blob/main/scripts/home_credit_eda.sql)

<h3 align="left">Olist — Marketplace Risk Analysis</h3>

Olist is a Brazilian e-commerce platform connecting small and medium-sized merchants to major online marketplaces — serving as the intermediary between independent sellers and customers across Brazil for order fulfillment, payment processing, and customer review collection. The platform spans 3,095 sellers and 99,441 orders across 2016 to 2018. The core analytical question: which combination of seller behavior, product category, and delivery patterns drives the highest concentration of late deliveries, low customer satisfaction, and revenue risk?


| | |
|---|---|
| **Domain** | E-Commerce · Marketplace Operations |
| **Tools** | MySQL |
| **SQL Skills** | Data Cleaning · Data Profiling · Relational Joins · Subquery Design · Bivariate Analysis · Conditional Logic · EDA  |
| **Dataset** | 8 tables · 99,441 orders · 35 columns retained |

[View Project README](https://github.com/arohit-talari/olist-ecommerce-analysis) **·** [View Data Cleaning Script](https://github.com/arohit-talari/olist-ecommerce-analysis/blob/main/scripts/olist_data_cleaning.sql) **·** [View EDA Script](https://github.com/arohit-talari/olist-ecommerce-analysis/blob/main/scripts/olist_eda.sql)

