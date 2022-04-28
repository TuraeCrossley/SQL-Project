-- USING WINDOW FUNCTION TO PRODUCE LINE NUMBERS
Select OD.OrderID, O.CustomerID, OD.UnitPrice*Quantity AS Total, ROW_NUMBER() OVER(PARTITION BY OD.OrderID Order BY CustomerID) AS LineNumber
FROM OrderDetails OD
INNER JOIN 
Orders O
ON 
OD.OrderID = O.OrderID
INNER JOIN 
Products P
ON 
OD.ProductID = P.ProductID


-- USING CASE STATEMENT CATEGORIZE STOCK LEVEL
SELECT ProductID, ProductName, UnitsInStock,
	CASE
		WHEN UnitsInStock = 0 THEN 'OUT OF STOCK'
		WHEN UnitsInStock < 50 THEN 'LOW STOCK'
		WHEN UnitsInStock BETWEEN 50 AND 100 THEN 'MEDIUM STOCK LEVEL'
		WHEN UnitsInStock > 100 THEN 'HIGH STOCK LEVEL'
		ELSE 'SEE MANAGER'
	END AS StockLevel
FROM 
Products
ORDER BY UnitsInStock

-- GETTING THE NUMBER ORDERS PER MONTH FOR THE YEAR 1997
SELECT DATENAME(month, orderdate) AS [Month], COUNT(ORDERID) AS No_Of_Orders 
FROM 
ORDERS
WHERE 
Orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
DATENAME(month, orderdate)
ORDER BY 
DATENAME(month, orderdate)

-- USING CTE TO RETRIEVE FIND THE MANAGER OF EACH EMPLOYEE
WITH mgrCTE AS 
(
	SELECT Employeeid, ReportsTo, firstname, lastname
	FROM employees
	WHERE employeeID = 2
	
	UNION ALL

	SELECT E.Employeeid, E.ReportsTo, E.firstname, E.lastname
	FROM mgrCTE AS M
	JOIN Employees AS E
		ON E.ReportsTo = M.EmployeeID
)
SELECT Employeeid,firstname, lastname, ReportsTo
FROM mgrCTE

--RETRIEVE THE PREVIOUS ORDERID FOR EACH ROW
SELECT CustomerID, OrderID, OrderDate, employeeid, (SELECT MAX(O.OrderID) FROM Orders O WHERE O.OrderID < OD.OrderID) AS Previous
FROM
Orders AS OD

-- CREATING A VIEW THEN CALCULATING THE RUNNING TOTAL BY THE YEAR
CREATE VIEW Orders_By_YEAR AS
	SELECT year(orderdate) AS Year_Of_Order, count(orderid) AS order_quantity
	FROM Orders 
	GROUP BY year(orderdate)

SELECT Year_Of_Order, order_quantity, (SELECT sum(O.order_quantity) FROM Orders_By_YEAR O WHERE O.Year_Of_Order <= OY.Year_Of_Order) AS RunningTotal
FROM Orders_By_YEAR OY
ORDER BY Year_Of_Order

-- RETRIEVING THE CUSTOMER WITH THE MOST ORDERS
SELECT customerID, orderdate, orderid, employeeid FROM ORDERS 
WHERE CustomerID IN (SELECT TOP(1) WITH TIES CustomerID
FROM ORDERS O
GROUP BY O.CustomerID 
ORDER BY COUNT(*) DESC)
ORDER BY ORDERDATE

-- CREATING A TABLE THEN PIVOTING THAT TABLE
IF OBJECT_ID('dbo.Orders_1', 'U') IS NOT NULL DROP TABLE dbo.Orders_1;
CREATE TABLE dbo.Orders_1
(
orderid INT NOT NULL,
orderdate DATE NOT NULL,
employeeid INT NOT NULL,
customerid VARCHAR(5) NOT NULL,
quantity INT NOT NULL,
CONSTRAINT PK_Orders_1 PRIMARY KEY(orderid)
);

INSERT INTO dbo.Orders_1(orderid, orderdate, employeeid, customerid, quantity)
VALUES
(30001, '20070802', 3, 'A', 10),
(10001, '20071224', 2, 'A', 12),
(10005, '20071224', 1, 'B', 20),
(40001, '20080109', 2, 'A', 40),
(10006, '20080118', 1, 'C', 14),
(20001, '20080212', 2, 'B', 12),
(40005, '20090212', 3, 'A', 10),
(20002, '20090216', 1, 'C', 20),
(30003, '20090418', 2, 'B', 15),
(30004, '20070418', 3, 'C', 22),
(30007, '20090907', 3, 'D', 30);

SELECT employeeid,
SUM(CASE WHEN customerid = 'A' THEN quantity END) AS A,
SUM(CASE WHEN customerid = 'B' THEN quantity END) AS B,
SUM(CASE WHEN customerid = 'C' THEN quantity END) AS C,
SUM(CASE WHEN customerid = 'D' THEN quantity END) AS D
FROM dbo.Orders_1
GROUP BY employeeid

--ROLLING UP ORDERS BASED ON YEAR, MONTH AND DATE
SELECT
YEAR(orderdate) AS orderyear,
MONTH(orderdate) AS ordermonth,
DAY(orderdate) AS orderday,
count(orderid) AS Orders
FROM dbo.Orders
GROUP BY ROLLUP(YEAR(orderdate), MONTH(orderdate), DAY(orderdate));

-- CREATE TABLE TO COMPLETE A MERGE 
CREATE TABLE dbo.CustomersUpdate
(
	[CustomerID] [nchar](5) NOT NULL,
	[CompanyName] [nvarchar](40) NOT NULL,
	[ContactName] [nvarchar](30) NULL,
	[ContactTitle] [nvarchar](30) NULL,
	[Address] [nvarchar](60) NULL,
	[City] [nvarchar](15) NULL,
	[Region] [nvarchar](15) NULL,
	[PostalCode] [nvarchar](10) NULL,
	[Country] [nvarchar](15) NULL,
	[Phone] [nvarchar](24) NULL,
	[Fax] [nvarchar](24) NULL,
CONSTRAINT PK_CustomersStage PRIMARY KEY([CustomerID])
);

INSERT INTO dbo.CustomersUpdate
VALUES
('PARIS', 'PEPSI', NULL, NULL,NULL, NULL,NULL, NULL,NULL, '(912) 222-2222', NULL),
('RANCH', 'Panda Express', NULL, NULL,NULL, NULL,NULL, NULL,NULL, '(912) 225-2852', NULL),
('GOOG', 'Google', 'Tina Mitchell', 'OWNER', '15 Ave', 'Miami', 'FL', '11254', 'USA', '(347) 777-7777', NULL);

MERGE INTO dbo.Customers AS CS
USING dbo.CustomersUpdate AS CU
ON CS.[CustomerID] = CU.[CustomerID]
WHEN MATCHED THEN
UPDATE SET
CS.companyname = CU.companyname,
CS.phone = CU.phone,
CS.address = CU.address
WHEN NOT MATCHED THEN
INSERT ([CustomerID], [CompanyName], [ContactName], [ContactTitle],[Address],[City],[Region],[PostalCode],[Country],[Phone],[Fax])
VALUES (CU.[CustomerID], CU.[CompanyName], CU.[ContactName], CU.[ContactTitle],CU.[Address],CU.[City],CU.[Region],CU.[PostalCode],CU.[Country],CU.[Phone],CU.[Fax]);