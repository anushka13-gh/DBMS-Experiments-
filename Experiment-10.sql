-- EXPERIMENT 10
-- SQL code extracted from Experiments_7_to_10_formatted.pdf.
-- Review/run in the matching MySQL schema before submission.

CREATE DATABASE IF NOT EXISTS Experiment10;

USE Experiment10;

DROP TABLE IF EXISTS Customer_Order;

CREATE TABLE Customer_Order (
Order_ID INT PRIMARY KEY,
Customer_ID INT,
Customer_Name VARCHAR(60),
City VARCHAR(50),
Product_Category VARCHAR(40),
Product_Name VARCHAR(80),
Quantity INT,
Unit_Price DECIMAL(10,2),
Order_Date DATE,
Payment_Mode VARCHAR(20),
Order_Status VARCHAR(20),
Total_Amount DECIMAL(12,2)
) ENGINE=InnoDB;

SET SESSION cte_max_recursion_depth = 11000;

INSERT INTO Customer_Order
(Order_ID, Customer_ID, Customer_Name, City, Product_Category, Product_Name,
Quantity, Unit_Price, Order_Date, Payment_Mode, Order_Status, Total_Amount)

WITH RECURSIVE seq AS (

SELECT 1 AS n
UNION ALL

SELECT n + 1 FROM seq WHERE n < 10000
)

SELECT
n,
1000 + MOD(n,1000),
CONCAT('Customer_', 1000 + MOD(n,1000)),
CASE MOD(n,5)
WHEN 0 THEN 'Delhi'
WHEN 1 THEN 'Lucknow'
WHEN 2 THEN 'Kanpur'
WHEN 3 THEN 'Noida'
ELSE 'Jaipur'
END,
CASE MOD(n,4)
WHEN 0 THEN 'Electronics'
WHEN 1 THEN 'Grocery'
WHEN 2 THEN 'Clothing'
ELSE 'Books'
END,
CONCAT('Product_', MOD(n,100)),
1 + MOD(n,5),
200 + MOD(n,50) * 25,
DATE_ADD('2026-01-01', INTERVAL MOD(n,300) DAY),
CASE MOD(n,3)
WHEN 0 THEN 'UPI'
WHEN 1 THEN 'CARD'
ELSE 'CASH'
END,
CASE MOD(n,4)
WHEN 0 THEN 'DELIVERED'
WHEN 1 THEN 'PENDING'
WHEN 2 THEN 'SHIPPED'
ELSE 'CANCELLED'
END,
(1 + MOD(n,5)) * (200 + MOD(n,50) * 25)
FROM seq;

-- QUERY 1 – VERIFY DATASET
SELECT COUNT(*) AS Total_Rows,
MIN(Order_Date) AS First_Order,
MAX(Order_Date) AS Last_Order
FROM Customer_Order;

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE City = 'Lucknow';

CREATE INDEX idx_city
ON Customer_Order(City);

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE City = 'Lucknow';

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE Customer_ID = 1250
AND Order_Date BETWEEN '2026-02-01' AND '2026-06-30';

CREATE INDEX idx_customer_date
ON Customer_Order(Customer_ID, Order_Date);

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE Customer_ID = 1250
AND Order_Date BETWEEN '2026-02-01' AND '2026-06-30';

EXPLAIN ANALYZE

SELECT COUNT(*) AS Total_Orders
FROM Customer_Order
WHERE YEAR(Order_Date) = 2026;

EXPLAIN ANALYZE

SELECT COUNT(*) AS Total_Orders
FROM Customer_Order
WHERE Order_Date >= '2026-01-01'
AND Order_Date < '2027-01-01';

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE Product_Category = 'Electronics'
AND Order_Status = 'DELIVERED';

CREATE INDEX idx_category_status
ON Customer_Order(Product_Category, Order_Status);

EXPLAIN ANALYZE

SELECT *
FROM Customer_Order
WHERE Product_Category = 'Electronics'
AND Order_Status = 'DELIVERED';

EXPLAIN ANALYZE

SELECT City, SUM(Total_Amount) AS Total_Sales
FROM Customer_Order
GROUP BY City
ORDER BY Total_Sales DESC;

CREATE INDEX idx_city_total
ON Customer_Order(City, Total_Amount);

EXPLAIN ANALYZE

SELECT City, SUM(Total_Amount) AS Total_Sales
FROM Customer_Order
GROUP BY City
ORDER BY Total_Sales DESC;

SHOW INDEX FROM Customer_Order;

SELECT
'Query 1 - City Filter' AS Query_Name,
'Before: no index on City' AS Before_Optimization,
'After: idx_city' AS After_Optimization
UNION ALL

SELECT
'Query 2 - Customer + Date',
'Before: no composite index',
'After: idx_customer_date'
UNION ALL

SELECT
'Query 3 - YEAR(Order_Date)',
'Before: function on column',
'After: date range rewrite'
UNION ALL

SELECT
'Query 4 - Category + Status',
'Before: no composite index',
'After: idx_category_status'
UNION ALL

SELECT
'Query 5 - City Aggregation',
'Before: no covering index',
'After: idx_city_total';
