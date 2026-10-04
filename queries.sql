-- ============================================================
-- Customer Transaction Data Analysis — SQL Queries
-- Database: customer_data.db (SQLite)
-- Run with: sqlite3 customer_data.db < queries.sql
-- ============================================================

-- 1. DATA CLEANING: build clean views from the raw (messy) tables
--    Raw data has: inconsistent city casing/whitespace, nulls, duplicate
--    transaction rows, and a few null transaction amounts.

DROP VIEW IF EXISTS customers_clean;
CREATE VIEW customers_clean AS
SELECT
    CustomerID,
    CASE WHEN City IS NULL THEN 'Unknown'
         ELSE TRIM(UPPER(SUBSTR(City,1,1)) || LOWER(SUBSTR(City,2)))
    END AS City,
    Segment,
    SignupDate
FROM customers_raw;

DROP VIEW IF EXISTS transactions_clean;
CREATE VIEW transactions_clean AS
SELECT DISTINCT
    TransactionID, CustomerID, TransactionDate, Amount, Category
FROM transactions_raw
WHERE Amount IS NOT NULL;

-- 2. Total revenue and transaction count per customer segment
SELECT
    c.Segment,
    COUNT(t.TransactionID) AS TransactionCount,
    ROUND(SUM(t.Amount), 2) AS TotalRevenue,
    ROUND(AVG(t.Amount), 2) AS AvgTransactionValue
FROM transactions_clean t
JOIN customers_clean c ON c.CustomerID = t.CustomerID
WHERE t.Category != 'Refund'
GROUP BY c.Segment
ORDER BY TotalRevenue DESC;

-- 3. Top 15 customers by lifetime spend
SELECT
    t.CustomerID,
    c.City,
    c.Segment,
    COUNT(t.TransactionID) AS NumTransactions,
    ROUND(SUM(t.Amount), 2) AS LifetimeSpend
FROM transactions_clean t
JOIN customers_clean c ON c.CustomerID = t.CustomerID
GROUP BY t.CustomerID
ORDER BY LifetimeSpend DESC
LIMIT 15;

-- 4. Monthly revenue trend
SELECT
    STRFTIME('%Y-%m', TransactionDate) AS YearMonth,
    ROUND(SUM(Amount), 2) AS Revenue,
    COUNT(*) AS Transactions
FROM transactions_clean
WHERE Category != 'Refund'
GROUP BY YearMonth
ORDER BY YearMonth;

-- 5. Revenue by city (geographic concentration)
SELECT
    c.City,
    COUNT(DISTINCT t.CustomerID) AS UniqueCustomers,
    ROUND(SUM(t.Amount), 2) AS Revenue
FROM transactions_clean t
JOIN customers_clean c ON c.CustomerID = t.CustomerID
WHERE t.Category != 'Refund'
GROUP BY c.City
ORDER BY Revenue DESC;

-- 6. Category mix (where the revenue actually comes from)
SELECT
    Category,
    COUNT(*) AS TransactionCount,
    ROUND(SUM(Amount), 2) AS TotalAmount
FROM transactions_clean
GROUP BY Category
ORDER BY TotalAmount DESC;

-- 7. Simple RFM-style segmentation: Recency (days since last purchase),
--    Frequency (# transactions), Monetary (total spend) per customer
WITH last_date AS (SELECT MAX(TransactionDate) AS max_d FROM transactions_clean),
rfm AS (
    SELECT
        t.CustomerID,
        CAST(JULIANDAY((SELECT max_d FROM last_date)) - JULIANDAY(MAX(t.TransactionDate)) AS INTEGER) AS Recency,
        COUNT(*) AS Frequency,
        ROUND(SUM(t.Amount), 2) AS Monetary
    FROM transactions_clean t
    WHERE t.Category != 'Refund'
    GROUP BY t.CustomerID
)
SELECT *,
    CASE
        WHEN Recency <= 60 AND Frequency >= 10 THEN 'Champion'
        WHEN Recency <= 120 AND Frequency >= 5 THEN 'Loyal'
        WHEN Recency > 300 THEN 'At Risk'
        ELSE 'Regular'
    END AS RFM_Segment
FROM rfm
ORDER BY Monetary DESC;

-- 8. Customers who signed up but never transacted (at-risk / onboarding gap)
SELECT c.CustomerID, c.City, c.Segment, c.SignupDate
FROM customers_clean c
LEFT JOIN transactions_clean t ON t.CustomerID = c.CustomerID
WHERE t.TransactionID IS NULL;
