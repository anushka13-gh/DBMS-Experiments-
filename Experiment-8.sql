-- EXPERIMENT 8
-- SQL code extracted from Experiments_7_to_10_formatted.pdf.
-- Review/run in the matching MySQL schema before submission.

CREATE DATABASE IF NOT EXISTS Experiment8;

USE Experiment8;

DROP TABLE IF EXISTS Transaction_Log;

DROP TABLE IF EXISTS Bank_Account;

CREATE TABLE Bank_Account (
Account_ID INT PRIMARY KEY,
Account_Holder VARCHAR(50),
Balance DECIMAL(12,2) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Transaction_Log (
Log_ID INT AUTO_INCREMENT PRIMARY KEY,
From_Account INT,
To_Account INT,
Amount DECIMAL(12,2),
Log_Time TIMESTAMP DEFAULT CURRENT_TIMESTAMP )
ENGINE=InnoDB;

INSERT INTO Bank_Account VALUES
(101,'Aarav Sharma',50000),
(102,'Riya Verma',30000),
(103,'Karan Mehta',20000);

-- QUERY 1 – VERIFY INITIAL BALANCES
SELECT * FROM Bank_Account ORDER BY Account_ID;

START TRANSACTION;

UPDATE Bank_Account

SET Balance = Balance - 5000
WHERE Account_ID = 101;

UPDATE Bank_Account

SET Balance = Balance + 5000
WHERE Account_ID = 102;

INSERT INTO Transaction_Log (From_Account, To_Account, Amount)
VALUES (101,102,5000);

COMMIT;

SELECT * FROM Bank_Account ORDER BY Account_ID;

START TRANSACTION;

UPDATE Bank_Account

SET Balance = Balance - 7000
WHERE Account_ID = 101;

UPDATE Bank_Account

SET Balance = Balance + 7000
WHERE Account_ID = 999;

ROLLBACK;

SELECT * FROM Bank_Account ORDER BY Account_ID;

START TRANSACTION;

UPDATE Bank_Account

SET Balance = Balance - 3000
WHERE Account_ID = 101;

SAVEPOINT after_debit;

UPDATE Bank_Account

SET Balance = Balance + 3000
WHERE Account_ID = 103;

SAVEPOINT after_credit;

UPDATE Bank_Account

SET Balance = Balance - 1000
WHERE Account_ID = 102;

ROLLBACK TO SAVEPOINT after_credit;

COMMIT;

SELECT * FROM Bank_Account ORDER BY Account_ID;

-- Run in Session 1
USE Experiment8;

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

UPDATE Bank_Account

SET Balance = Balance + 10000
WHERE Account_ID = 101;

-- Do NOT COMMIT yet.
SELECT Account_ID, Balance
FROM Bank_Account
WHERE Account_ID = 101;

-- Run while Session 1 is still uncommitted
USE Experiment8;

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

START TRANSACTION;

SELECT Account_ID, Balance
FROM Bank_Account
WHERE Account_ID = 101;

COMMIT;

-- Session 1
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT Balance
FROM Bank_Account
WHERE Account_ID = 102;

-- Pause here and execute Session 2.
-- Session 2
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

UPDATE Bank_Account

SET Balance = Balance + 2000
WHERE Account_ID = 102;

COMMIT;

-- Back to Session 1
SELECT Balance
FROM Bank_Account
WHERE Account_ID = 102;

COMMIT;

-- Session 1
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

START TRANSACTION;

SELECT COUNT(*) AS Accounts_Above_40000
FROM Bank_Account
WHERE Balance > 40000;

-- Pause here.
-- Session 2
INSERT INTO Bank_Account VALUES (104,'Neha Gupta',60000);

COMMIT;

-- Session 1
SELECT COUNT(*) AS Accounts_Above_40000
FROM Bank_Account
WHERE Balance > 40000;

COMMIT;

SELECT @@transaction_isolation AS Current_Isolation_Level;

SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT @@transaction_isolation AS Isolation_Level;

SET SESSION TRANSACTION ISOLATION LEVEL READ
COMMITTED; SELECT @@transaction_isolation AS Isolation_Level;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE
READ; SELECT @@transaction_isolation AS Isolation_Level;

SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

SELECT @@transaction_isolation AS Isolation_Level;
