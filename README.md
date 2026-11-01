# AdventureWorks2025 Sales & Business Performance Analysis

## Executive Summary
This repository contains an end-to-end SQL Data Analysis project leveraging the AdventureWorks2025 relational database. The project progresses from initial database auditing and data quality preparation to exploratory data analysis (EDA), advanced business queries, and strategic business recommendations.

---
```
## Repository Structure
├── 01_data_audit.sql
├── 02_data_cleaning.sql
├── 03_exploratory_data_analysis.sql
├── 04_business_analysis.sql
├── 05_insights_and_recommendations.md
└── README.md
```
---

## Project Roadmap & Execution Summary

### Phase 1: Database Setup and Audit (01_data_audit.sql)
* Audited core schemas (Sales, Production, Person), validated primary/foreign keys, and verified column data types.

### Phase 2: Data Quality & Preparation (02_data_cleaning.sql)
* Built clean baseline views (sales.vw_cleansalesorderheader) to standardize NULL handling, sales channel classifications, and sales representative mapping.

### Phase 3: Exploratory Data Analysis (03_exploratory_data_analysis.sql)
* Derived executive baselines across total revenue, order volume, customer reach, multi-year trend patterns, repeat customer rates, and territory distribution.

### Phase 4: Business Analysis & Performance (04_business_analysis.sql)
* Executed targeted business logic including RFM customer segmentation, product margin calculations, sales channel performance (Online vs. Reseller), quota attainment, and promotional discount impact.

### Phase 5: Executive Insights (05_insights_and_recommendations.md)
* Formulated data-driven strategy covering B2B customer churn prevention, low-velocity catalog liquidation, discount structure redesign, and high-margin accessory category growth.

---

## Tech Stack
* **Language & Engine:** T-SQL / SQL Server (AdventureWorks2025)
* **Environment:** Visual Studio Code / SSMS
* **Documentation:** Markdown (.md)


