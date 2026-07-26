# End-to-End Neobank Customer Churn Analytics

## Project Overview

This project demonstrates an end-to-end Customer Churn Analytics solution built using **Python, SQL Server, and Power BI**. The objective was to identify customer churn patterns, evaluate customer engagement, detect operational risks, and provide data-driven recommendations that support customer retention.

The project follows a complete analytics workflow, beginning with raw data preparation in Python, automated loading into SQL Server, business analysis using SQL, and interactive dashboard development in Power BI.

---

# Business Problem

Customer retention is one of the biggest challenges facing digital banks.

Although thousands of customers remain active, some gradually reduce their engagement before eventually leaving the platform.

The business needed to answer questions such as:

- Which customer groups are most likely to churn?
- Which subscription plans have the highest customer friction?
- Does incomplete KYC affect feature engagement?
- Which customers require early intervention?
- How can management improve customer retention?

---

# Project Objectives

The objectives of this project were to:

- Clean and prepare customer data using Python.
- Build an automated ETL pipeline from Python to SQL Server.
- Perform SQL business analysis to answer key business questions.
- Develop an interactive Power BI dashboard.
- Generate actionable business recommendations for customer retention.

---

# Dataset Overview

The dataset contains customer information including:

- Customer ID
- Country
- Age
- Income Band
- Occupation Type
- Subscription Plan
- KYC Status
- Account Balance
- Monthly Deposits
- Monthly Transactions
- Failed Logins
- Support Tickets
- Core Feature Score
- AI Risk Band
- Customer Friction Score
- Churn Indicators

After data cleaning, the final dataset contained:

- **2,005 customers**
- **33 columns**
- **0 missing values**
- **0 duplicate records**

---

# Technology Stack

- Python
- Pandas
- NumPy
- SQL Server
- SQLAlchemy
- PyODBC
- Power BI
- DAX
- GitHub

---

# End-to-End ETL Pipeline

```text
Raw Excel Dataset
        │
        ▼
Python Data Cleaning
        │
        ▼
Feature Engineering
        │
        ▼
Data Validation
        │
        ▼
Automated ETL Pipeline
(Python → SQL Server)
        │
        ▼
SQL Business Analysis
        │
        ▼
Power BI Dashboard
        │
        ▼
Business Insights
```

The automated ETL pipeline performs the following tasks:

- Connects Python to SQL Server using SQLAlchemy and PyODBC.
- Loads the cleaned dataset directly into SQL Server.
- Verifies successful data loading.
- Preserves the production table used by Power BI.
- Eliminates the need for manual CSV imports.

---

# SQL Business Analysis

The project answers several business questions including:

### Query 1 – Silent Churn Detector

Identifies customer groups with:

- Low deposit coverage
- High customer friction
- Increased churn risk

---

### Query 2 – Friction Spike Vulnerability

Detects customers experiencing:

- High support ticket volumes
- Low account balances
- High operational risk

---

### Query 3 – Plan Feature Engagement Stress Test

Compares customer engagement between:

- Completed KYC
- Pending KYC

to evaluate whether KYC completion influences feature adoption.

---

### Query 4 – False Churn Alarm Audit

Checks whether AI risk classification incorrectly labels highly engaged customers as High Risk.

---

# Power BI Dashboard

The dashboard consists of four pages:

### Executive Overview

- KPI Cards
- Customer Distribution
- AI Risk Distribution
- KYC Status
- Retention Summary

### Customer Demographics

- Country Analysis
- Occupation Distribution
- Income Band Analysis
- Subscription Plans

### Churn & Engagement

- Feature Engagement
- Customer Friction
- Churn Risk
- Plan Comparison

### AI Insights

- What-if Analysis
- High-Risk Customers
- Estimated Retained Value
- Business Recommendations

---

# Key Business Insights

The analysis revealed that:

- Customer friction is strongly associated with churn risk.
- Incomplete KYC reduces customer engagement.
- Subscription plans perform differently across customer segments.
- High-risk customers can be identified early using behavioural indicators.
- Automated analytics enables faster business decision-making.

---

# Business Recommendations

- Improve onboarding for customers with Pending KYC.
- Reduce customer support response times.
- Monitor high-friction customers proactively.
- Increase engagement for Free plan customers.
- Continue monitoring AI Risk Band through Power BI dashboards.

---

# Repository Contents

- Python Notebook
- SQL Analysis Scripts
- Power BI Dashboard
- Executive Presentation
- Automated ETL Pipeline
- README Documentation

---

# Author

**Jadesola Ogunkayode**

Aspiring Data Analyst | Python | SQL Server | Power BI | Data Visualisation
