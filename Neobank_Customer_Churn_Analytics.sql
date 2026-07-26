
-- =========================================================
-- NEOBANK CUSTOMER CHURN AND ENGAGEMENT ANALYTICS
-- SQL SERVER BUSINESS ANALYSIS
-- =========================================================
-- Author: Jadesola Ogunkayode
--
-- Purpose:
-- This script analyses the cleaned Neobank customer dataset
-- loaded automatically from Python into SQL Server.
--
-- Database: Neobank_Analytics
-- Production table: dbo.neobank_customer_churn_cleaned
--
-- The analysis covers:
-- 1. Data validation
-- 2. Silent churn detection
-- 3. Friction spike vulnerability
-- 4. KYC and feature-engagement stress testing
-- 5. False churn alarm auditing
-- =========================================================

USE Neobank_Analytics;
GO

-- DATA VALIDATION
-- ============================================

SELECT COUNT(*) AS Total_Rows
FROM dbo.neobank_customer_churn_cleaned;



-- QUERY 1: SILENT CHURN DETECTOR
-- ============================================
-- Monthly deposits are compared with account balances at the
-- Plan_Type and KYC_Status group level.
-- Groups are returned when deposit coverage is below 30%
-- and more than 30% of customers experience service friction.

SELECT
    Plan_Type,
    KYC_Status,

    COUNT(*) AS Total_Customers,

    SUM(Monthly_Deposits) AS Total_Deposits,
    SUM(Account_Balance) AS Total_Account_Balance,

    ROUND(
        SUM(Monthly_Deposits) * 100.0
        / NULLIF(SUM(Account_Balance), 0),
        2
    ) AS Deposit_Coverage_Percentage,

    SUM(
        CASE
            WHEN Failed_Logins > 0
                 OR Support_Tickets > 0
            THEN 1
            ELSE 0
        END
    ) AS Customers_With_Friction,

    ROUND(
        SUM(
            CASE
                WHEN Failed_Logins > 0
                     OR Support_Tickets > 0
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Friction_Percentage

FROM dbo.neobank_customer_churn_cleaned

GROUP BY
    Plan_Type,
    KYC_Status

HAVING
    SUM(Monthly_Deposits)
        < 0.30 * SUM(Account_Balance)

    AND

    SUM(
        CASE
            WHEN Failed_Logins > 0
                 OR Support_Tickets > 0
            THEN 1
            ELSE 0
        END
    ) * 1.0 / COUNT(*) > 0.30;



-- QUERY 2: FRICTION SPIKE VULNERABILITY FINDER
-- ============================================
-- Dataset limitation:
-- The dataset contains one balance snapshot per customer.
-- Therefore, a true month-on-month balance decline cannot be calculated.
-- An account balance below 50% of the customer's plan average
-- is used as a proxy for a significant balance plunge.

SELECT
    c.Customer_ID,
    c.Signup_Date,
    c.Snapshot_Month,
    c.Plan_Type,
    c.KYC_Status,
    c.Account_Balance,
    c.Support_Tickets,
    c.Failed_Logins,
    c.AI_Risk_Band,
    c.Customer_Friction_Score,

    (
        SELECT CAST(
            ROUND(
                AVG(CAST(p.Support_Tickets AS DECIMAL(10,2))),
                2
            ) AS DECIMAL(10,2)
        )
        FROM dbo.neobank_customer_churn_cleaned AS p
        WHERE p.Plan_Type = c.Plan_Type
    ) AS Plan_Average_Support_Tickets,

    (
        SELECT CAST(
            ROUND(
                AVG(CAST(p.Account_Balance AS DECIMAL(18,2))),
                2
            ) AS DECIMAL(18,2)
        )
        FROM dbo.neobank_customer_churn_cleaned AS p
        WHERE p.Plan_Type = c.Plan_Type
    ) AS Plan_Average_Account_Balance

FROM dbo.neobank_customer_churn_cleaned AS c

WHERE
    c.Support_Tickets >
    (
        SELECT AVG(
            CAST(p.Support_Tickets AS DECIMAL(10,2))
        )
        FROM dbo.neobank_customer_churn_cleaned AS p
        WHERE p.Plan_Type = c.Plan_Type
    )

    AND

    c.Account_Balance <
    (
        SELECT
            0.50 * AVG(
                CAST(p.Account_Balance AS DECIMAL(18,2))
            )
        FROM dbo.neobank_customer_churn_cleaned AS p
        WHERE p.Plan_Type = c.Plan_Type
    )

ORDER BY
    c.Support_Tickets DESC,
    c.Account_Balance ASC;


-- QUERY 3: PLAN FEATURE ENGAGEMENT STRESS TEST
-- ============================================
-- Objective:
-- Compare the average Core_Feature_Score for customers
-- with Completed KYC against customers with Pending KYC.
-- Return only Plan Types where Pending KYC reduces
-- average engagement by more than 15 points.

SELECT
    Plan_Type,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        ) AS DECIMAL(10,2)
    ) AS Completed_KYC_Average_Feature_Score,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        ) AS DECIMAL(10,2)
    ) AS Pending_KYC_Average_Feature_Score,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        )
        -
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        )
        AS DECIMAL(10,2)
    ) AS Engagement_Score_Drop

FROM dbo.neobank_customer_churn_cleaned

GROUP BY
    Plan_Type

HAVING
    AVG(
        CASE
            WHEN KYC_Status = 'Completed'
            THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
        END
    )
    -
    AVG(
        CASE
            WHEN KYC_Status = 'Pending'
            THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
        END
    ) > 15

ORDER BY
    Engagement_Score_Drop DESC;

-- QUERY 3 VALIDATION
-- ============================================
-- Result:
-- No Plan Type satisfies the project requirement
-- of an engagement score drop greater than 15 points.
--
-- The query below displays the actual engagement
-- score differences for all Plan Types.

SELECT
    Plan_Type,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        ) AS DECIMAL(10,2)
    ) AS Completed_KYC_Average,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        ) AS DECIMAL(10,2)
    ) AS Pending_KYC_Average,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        )
        -
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(Core_Feature_Score AS DECIMAL(10,2))
            END
        )
        AS DECIMAL(10,2)
    ) AS Difference

FROM dbo.neobank_customer_churn_cleaned

GROUP BY
    Plan_Type

ORDER BY
    Difference DESC;

-- QUERY 4: FALSE CHURN ALARM AUDIT
-- ============================================
-- Objective:
-- Identify false-positive churn risk classifications.
-- A false alarm occurs when a customer is labelled
-- as High risk but has a healthy Core_Feature_Score
-- of 80 or more.
--
-- False Alarm Percentage =
-- High-risk customers with Core_Feature_Score >= 80
-- divided by all High-risk customers within the plan.

SELECT
    Plan_Type,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE
            WHEN AI_Risk_Band = 'High'
            THEN 1
            ELSE 0
        END
    ) AS Total_High_Risk_Labels,

    SUM(
        CASE
            WHEN AI_Risk_Band = 'High'
                 AND Core_Feature_Score >= 80
            THEN 1
            ELSE 0
        END
    ) AS False_Churn_Alarms,

    CAST(
        ROUND(
            SUM(
                CASE
                    WHEN AI_Risk_Band = 'High'
                         AND Core_Feature_Score >= 80
                    THEN 1
                    ELSE 0
                END
            ) * 100.0
            /
            NULLIF(
                SUM(
                    CASE
                        WHEN AI_Risk_Band = 'High'
                        THEN 1
                        ELSE 0
                    END
                ),
                0
            ),
            2
        ) AS DECIMAL(10,2)
    ) AS False_Alarm_Percentage

FROM dbo.neobank_customer_churn_cleaned

GROUP BY
    Plan_Type

HAVING
    SUM(
        CASE
            WHEN AI_Risk_Band = 'High'
            THEN 1
            ELSE 0
        END
    ) > 0

ORDER BY
    False_Alarm_Percentage DESC;

-- ============================================
-- QUERY 4 RESULT INTERPRETATION
-- ============================================
-- Result:
-- No false churn alarms were detected.
--
-- This is expected because the AI_Risk_Band was
-- recalculated during the Python data engineering
-- phase using Core_Feature_Score.
--
-- Therefore, customers with Core_Feature_Score >= 80
-- are classified as Low risk rather than High risk.