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
-- Database:
-- Neobank_Analytics
--
-- Production table:
-- dbo.neobank_customer_churn_cleaned
--
-- The analysis covers:
-- 1. Production data validation
-- 2. AI Risk Band validation
-- 3. Transaction Volatility Index validation
-- 4. Silent churn detection
-- 5. Friction spike vulnerability
-- 6. KYC and feature-engagement stress testing
-- 7. False churn alarm auditing
--
-- SQL constraints:
-- - No Common Table Expressions (CTEs)
-- - No window functions
-- =========================================================


USE Neobank_Analytics;
GO


-- =========================================================
-- SECTION 1: PRODUCTION DATA VALIDATION
-- =========================================================

-- Confirm the number of records loaded into SQL Server.
-- Expected result: 2,005 rows.

SELECT
    COUNT(*) AS Total_Rows
FROM dbo.neobank_customer_churn_cleaned;
GO


-- Check for duplicate Customer_ID values.
-- Expected result: zero rows.

SELECT
    Customer_ID,
    COUNT(*) AS Duplicate_Count
FROM dbo.neobank_customer_churn_cleaned
GROUP BY
    Customer_ID
HAVING
    COUNT(*) > 1;
GO


-- Validate the corrected AI Risk Band distribution.
--
-- Project specification:
-- Core_Feature_Score < 30  = High
-- Core_Feature_Score < 70  = Medium
-- Core_Feature_Score >= 70 = Low
--
-- Expected results:
-- Low     = 970
-- Medium  = 881
-- High    = 154

SELECT
    AI_Risk_Band,
    COUNT(*) AS Customer_Count
FROM dbo.neobank_customer_churn_cleaned
GROUP BY
    AI_Risk_Band
ORDER BY
    Customer_Count DESC;
GO


-- Validate the AI Risk Band against the project thresholds.
-- Expected result: zero incorrectly classified records.

SELECT
    Customer_ID,
    Core_Feature_Score,
    AI_Risk_Band
FROM dbo.neobank_customer_churn_cleaned
WHERE
       (Core_Feature_Score < 30
        AND AI_Risk_Band <> 'High')

    OR (Core_Feature_Score >= 30
        AND Core_Feature_Score < 70
        AND AI_Risk_Band <> 'Medium')

    OR (Core_Feature_Score >= 70
        AND AI_Risk_Band <> 'Low');
GO


-- Validate the corrected Transaction Volatility Index.
--
-- Formula:
-- Standard deviation / mean × 100
--
-- Expected approximate values:
-- Business = 36.6649
-- Free     = 46.3090
-- Plus     = 38.8478
-- Premium  = 28.1762

SELECT DISTINCT
    Plan_Type,
    Plan_Transaction_Volatility_Index
FROM dbo.neobank_customer_churn_cleaned
ORDER BY
    Plan_Type;
GO


-- Confirm that the volatility index is consistent
-- within each Plan Type.
-- Expected result: one volatility value per plan.

SELECT
    Plan_Type,
    COUNT(
        DISTINCT Plan_Transaction_Volatility_Index
    ) AS Number_Of_Volatility_Values
FROM dbo.neobank_customer_churn_cleaned
GROUP BY
    Plan_Type
ORDER BY
    Plan_Type;
GO


-- =========================================================
-- QUERY 1: SILENT CHURN DETECTOR
-- =========================================================
-- Objective:
-- Identify Plan Type and KYC Status groups that may
-- demonstrate silent churn behaviour.
--
-- Monthly deposits are compared with account balances
-- at the Plan_Type and KYC_Status group level.
--
-- Groups are returned when:
-- 1. Deposit coverage is below 30%.
-- 2. More than 30% of customers experience friction.
--
-- Friction is defined as:
-- Failed_Logins > 0 OR Support_Tickets > 0.
-- =========================================================

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
        ) * 100.0
        / NULLIF(COUNT(*), 0),
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
    ) * 1.0
        / NULLIF(COUNT(*), 0) > 0.30

ORDER BY
    Deposit_Coverage_Percentage ASC,
    Friction_Percentage DESC;
GO


-- =========================================================
-- QUERY 2: FRICTION SPIKE VULNERABILITY
-- =========================================================
-- Objective:
-- Identify individual customers whose support activity
-- is above the average for their Plan Type and whose
-- account balance is below 50% of the average balance
-- for that Plan Type.
--
-- Dataset limitation:
-- The dataset contains one current snapshot per customer.
-- It does not contain a historical account-balance series.
--
-- Therefore, an account balance below 50% of the
-- Plan Type average is used as a proxy for a balance plunge.
--
-- Performance improvement:
-- A pre-aggregated derived table calculates the plan
-- averages once and joins them to the customer records.
--
-- This avoids repeated correlated subqueries while still
-- complying with the restriction against CTEs and
-- window functions.
-- =========================================================

SELECT
    c.Customer_ID,
    c.Signup_Date,
    c.Plan_Type,
    c.Account_Balance,
    c.Support_Tickets,
    p_avg.Avg_Support_Tickets,
    p_avg.Avg_Account_Balance

FROM dbo.neobank_customer_churn_cleaned AS c

INNER JOIN
(
    SELECT
        Plan_Type,

        AVG(
            CAST(
                Support_Tickets AS DECIMAL(10,2)
            )
        ) AS Avg_Support_Tickets,

        AVG(
            CAST(
                Account_Balance AS DECIMAL(18,2)
            )
        ) AS Avg_Account_Balance

    FROM dbo.neobank_customer_churn_cleaned

    GROUP BY
        Plan_Type
) AS p_avg

    ON c.Plan_Type = p_avg.Plan_Type

WHERE
    c.Support_Tickets > p_avg.Avg_Support_Tickets

    AND

    c.Account_Balance
        < 0.50 * p_avg.Avg_Account_Balance

ORDER BY
    c.Support_Tickets DESC,
    c.Account_Balance ASC;
GO


-- =========================================================
-- QUERY 3: PLAN FEATURE ENGAGEMENT STRESS TEST
-- =========================================================
-- Objective:
-- Compare the average Core_Feature_Score for customers
-- with Completed KYC against customers with Pending KYC.
--
-- Return only Plan Types where Pending KYC reduces
-- average feature engagement by more than 15 points.
--
-- Dataset result:
-- No Plan Type currently satisfies the required
-- engagement-score drop of more than 15 points.
-- =========================================================

SELECT
    Plan_Type,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        ) AS DECIMAL(10,2)
    ) AS Completed_KYC_Average_Feature_Score,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        ) AS DECIMAL(10,2)
    ) AS Pending_KYC_Average_Feature_Score,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        )
        -
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
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
            THEN CAST(
                Core_Feature_Score AS DECIMAL(10,2)
            )
        END
    )
    -
    AVG(
        CASE
            WHEN KYC_Status = 'Pending'
            THEN CAST(
                Core_Feature_Score AS DECIMAL(10,2)
            )
        END
    ) > 15

ORDER BY
    Engagement_Score_Drop DESC;
GO


-- =========================================================
-- QUERY 3 VALIDATION
-- =========================================================
-- This validation query displays the actual engagement
-- score difference for every Plan Type, including those
-- that do not meet the threshold of more than 15 points.
-- =========================================================

SELECT
    Plan_Type,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        ) AS DECIMAL(10,2)
    ) AS Completed_KYC_Average,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        ) AS DECIMAL(10,2)
    ) AS Pending_KYC_Average,

    CAST(
        AVG(
            CASE
                WHEN KYC_Status = 'Completed'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        )
        -
        AVG(
            CASE
                WHEN KYC_Status = 'Pending'
                THEN CAST(
                    Core_Feature_Score AS DECIMAL(10,2)
                )
            END
        )
        AS DECIMAL(10,2)
    ) AS Difference

FROM dbo.neobank_customer_churn_cleaned

GROUP BY
    Plan_Type

ORDER BY
    Difference DESC;
GO


-- =========================================================
-- QUERY 4: FALSE CHURN ALARM AUDIT
-- =========================================================
-- Objective:
-- Identify false-positive churn risk classifications.
--
-- A false alarm is defined as a customer who:
-- 1. Is classified as High risk; and
-- 2. Has a healthy Core_Feature_Score of 80 or more.
--
-- False Alarm Percentage:
-- High-risk customers with Core_Feature_Score >= 80
-- divided by all High-risk customers within the plan.
--
-- Note:
-- The false-alarm threshold of 80 is retained as the
-- analytical definition used in this business query.
-- It is separate from the corrected AI Risk Band
-- classification thresholds.
-- =========================================================

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
GO


-- =========================================================
-- QUERY 4 RESULT INTERPRETATION
-- =========================================================
-- Expected result:
-- No false churn alarms should be detected.
--
-- AI_Risk_Band is recalculated during the Python
-- data-engineering phase using:
--
-- Core_Feature_Score < 30  = High
-- Core_Feature_Score < 70  = Medium
-- Core_Feature_Score >= 70 = Low
--
-- Therefore, a customer with a Core_Feature_Score
-- of 80 or more cannot be classified as High risk.
-- =========================================================


-- =========================================================
-- FINAL SUMMARY VALIDATION
-- =========================================================
-- This final query provides one row containing the main
-- production-quality checks for the completed dataset.
-- =========================================================

SELECT
    COUNT(*) AS Total_Rows,

    COUNT(DISTINCT Customer_ID)
        AS Distinct_Customers,

    SUM(
        CASE
            WHEN AI_Risk_Band = 'High'
            THEN 1
            ELSE 0
        END
    ) AS High_Risk_Customers,

    SUM(
        CASE
            WHEN AI_Risk_Band = 'Medium'
            THEN 1
            ELSE 0
        END
    ) AS Medium_Risk_Customers,

    SUM(
        CASE
            WHEN AI_Risk_Band = 'Low'
            THEN 1
            ELSE 0
        END
    ) AS Low_Risk_Customers

FROM dbo.neobank_customer_churn_cleaned;
GO