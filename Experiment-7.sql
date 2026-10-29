-- Experiment 7
-- Aim:
-- Given a denormalized Sales table, identify functional dependencies and normalize
-- step-by-step from UNF to 3NF and BCNF. Verify lossless join and dependency
-- preservation using SQL queries.
--
-- Extracted and formatted from EXP-07.pdf.
-- Run in MySQL. Execute this script in a fresh schema because it creates tables.
-- The final INSERT at the bottom is an intentional constraint-violation test
-- and is expected to fail with a duplicate primary key.

-- STEP 1: Create 1NF table and insert the denormalized data.

CREATE TABLE Sales_1NF (
    order_id INT,
    product_id INT,
    customer_id INT,
    customer_name VARCHAR(50),
    product_name VARCHAR(50),
    quantity INT,
    discount_code VARCHAR(20),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO Sales_1NF VALUES
    (1, 101, 501, 'Aarav Sharma', 'Laptop', 1, 'LAP10'),
    (1, 102, 501, 'Aarav Sharma', 'Mouse', 2, 'MOU20'),
    (2, 101, 502, 'Diya Kumar', 'Laptop', 1, 'LAP10'),
    (3, 103, 501, 'Aarav Sharma', 'Keyboard', 1, 'KEY50');

-- STEP 2: Convert to 2NF by removing partial dependencies.

-- Orders: attributes depending on order_id.
CREATE TABLE Orders_2NF (
    order_id INT PRIMARY KEY,
    customer_id INT,
    customer_name VARCHAR(50)
);

INSERT INTO Orders_2NF (order_id, customer_id, customer_name)
SELECT DISTINCT order_id, customer_id, customer_name
FROM Sales_1NF;

-- Products: attributes depending on product_id.
CREATE TABLE Products_2NF (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(50)
);

INSERT INTO Products_2NF (product_id, product_name)
SELECT DISTINCT product_id, product_name
FROM Sales_1NF;

-- Order details: attributes depending on the full composite key.
CREATE TABLE OrderDetails_2NF (
    order_id INT,
    product_id INT,
    quantity INT,
    discount_code VARCHAR(20),
    PRIMARY KEY (order_id, product_id)
);

INSERT INTO OrderDetails_2NF (order_id, product_id, quantity, discount_code)
SELECT order_id, product_id, quantity, discount_code
FROM Sales_1NF;

-- STEP 3: Convert to 3NF by removing transitive dependencies.

CREATE TABLE Customers_3NF (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50)
);

INSERT INTO Customers_3NF (customer_id, customer_name)
SELECT DISTINCT customer_id, customer_name
FROM Orders_2NF;

CREATE TABLE Orders_3NF (
    order_id INT PRIMARY KEY,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customers_3NF(customer_id)
);

INSERT INTO Orders_3NF (order_id, customer_id)
SELECT order_id, customer_id
FROM Orders_2NF;

-- STEP 4: Convert to BCNF.
-- The PDF identifies the dependency discount_code -> product_id.

CREATE TABLE Discounts_BCNF (
    discount_code VARCHAR(20) PRIMARY KEY,
    product_id INT,
    FOREIGN KEY (product_id) REFERENCES Products_2NF(product_id)
);

INSERT INTO Discounts_BCNF (discount_code, product_id)
SELECT DISTINCT discount_code, product_id
FROM OrderDetails_2NF;

CREATE TABLE OrderItems_BCNF (
    order_id INT,
    discount_code VARCHAR(20),
    quantity INT,
    PRIMARY KEY (order_id, discount_code),
    FOREIGN KEY (order_id) REFERENCES Orders_3NF(order_id),
    FOREIGN KEY (discount_code) REFERENCES Discounts_BCNF(discount_code)
);

INSERT INTO OrderItems_BCNF (order_id, discount_code, quantity)
SELECT order_id, discount_code, quantity
FROM OrderDetails_2NF;

-- STEP 5: Verify lossless join.
-- This query should reconstruct the four original sales rows.

SELECT
    o.order_id,
    d.product_id,
    c.customer_id,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.discount_code
FROM Orders_3NF AS o
JOIN Customers_3NF AS c
    ON o.customer_id = c.customer_id
JOIN OrderItems_BCNF AS oi
    ON o.order_id = oi.order_id
JOIN Discounts_BCNF AS d
    ON oi.discount_code = d.discount_code
JOIN Products_2NF AS p
    ON d.product_id = p.product_id
ORDER BY o.order_id, d.product_id;

-- STEP 6: Verify dependency preservation using constraints.

-- FD: customer_id -> customer_name.
-- Update the customer's name and view the customer table.
UPDATE Customers_3NF
SET customer_name = 'Aarav S.'
WHERE customer_id = 501;

SELECT * FROM Customers_3NF;

-- FD: discount_code -> product_id.
-- This is an intentional negative test: LAP10 already exists as the primary key.
-- The following statement is expected to fail with a duplicate primary key error.
INSERT INTO Discounts_BCNF (discount_code, product_id)
VALUES ('LAP10', 103);
