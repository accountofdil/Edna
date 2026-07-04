-- Database Creation

CREATE DATABASE digital_retail_firm_analysis;
GO

USE digital_retail_firm_analysis;
GO

CREATE TABLE Customers(
					CustomerID INT PRIMARY KEY IDENTITY(1, 1),
					FirstName NVARCHAR(50),
					LastName NVARCHAR(50),
					Email NVARCHAR(100),
					Phone NVARCHAR(50),
					Address NVARCHAR(255),
					City NVARCHAR(50),
					State NVARCHAR(50),
					ZipCode NVARCHAR(50),
					Country NVARCHAR(50),
					CreatedAt DATETIME DEFAULT GETDATE()
					);

CREATE TABLE Products(
					ProductID INT PRIMARY KEY IDENTITY(1, 1),
					ProductName NVARCHAR(100),
					CategoryID INT,
					Price DECIMAL(10, 2),
					Stock INT, 
					CreatedAt DATETIME DEFAULT GETDATE()
					);

CREATE TABLE Orders(
				OrderID INT PRIMARY KEY IDENTITY(1, 1),
				CustomerId INT,
				OrderDate DATETIME DEFAULT GETDATE(),
				TotalAmount DECIMAL(10, 2),
				FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
				);

EXEC sp_rename 'digital_retail_firm_analysis.dbo.Orders.CustomerId', 'CustomerID', 'COLUMN';

CREATE TABLE OrderItems(
					OrderItemID INT PRIMARY KEY IDENTITY(1, 1),
					OrderID INT,
					ProductID INT,
					Quantity INT,
					Price DECIMAL(10, 2),
					FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
					FOREIGN KEY(OrderID) REFERENCES Orders(OrderID)
					);

CREATE TABLE Categories(
					CategoryID INT PRIMARY KEY IDENTITY(1, 1),
					CategoryName NVARCHAR(100),
					Description NVARCHAR(255)
					);

INSERT INTO Categories (CategoryName, Description) 
VALUES 
('Electronics', 'Devices and Gadgets'),
('Books', 'Printed and Electronic Books'),
('Clothing', 'Apparel and Accessories');

INSERT INTO Products(ProductName, CategoryID, Price, Stock)
VALUES 
('Smartphone', 1, 699.99, 50),
('Laptop', 1, 999.99, 30),
('T-shirt', 2, 19.99, 100),
('Jeans', 2, 49.99, 60),
('Fiction Novel', 3, 14.99, 200),
('Science Journal', 3, 29.99, 150);

INSERT INTO Customers(FirstName, LastName, Email, Phone, Address, City, State, ZipCode, Country)
VALUES 
('Sameer', 'Khanna', 'sameer.khanna@example.com', '123-456-7890', '123 Elm St.', 'Springfield', 'IL', '62701', 'USA'),
('Harshad', 'Patel', 'harshad.patel@example.com', '345-678-9012', '789 Dalal St.', 'Mumbai', 'Maharashtra', '41520', 'INDIA'),
('Jane', 'Smith', 'jane.smith@example.com', '234-567-8901', '456 Oak St.', 'Madison', 'WI', '53703', 'USA');

INSERT INTO Orders(CustomerId, OrderDate, TotalAmount)
VALUES 
(1, GETDATE(), 719.98),
(2, GETDATE(), 49.99),
(3, GETDATE(), 44.98);

INSERT INTO OrderItems(OrderID, ProductID, Quantity, Price)
VALUES 
(1, 1, 1, 699.99),
(1, 3, 1, 19.99),
(2, 4, 1,  49.99),
(3, 5, 1, 14.99),
(3, 6, 1, 29.99);

SELECT * FROM Categories;
SELECT * FROM Products;
SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM OrderItems;


-- Data Analysis

-- Calculate the average order value

SELECT AVG(TotalAmount) AS AverageOrderValue FROM Orders;

-- Retrieve all orders for a specific customer

SELECT o.OrderID, o.OrderDate, o.TotalAmount, oi.ProductID, oi.Quantity, oi.Price, p.ProductName
FROM Orders o
JOIN OrderItems oi 
ON o.OrderID = oi.OrderID
JOIN Products p 
ON oi.ProductID = p.ProductID
WHERE o.CustomerID = 1;

-- Find the total sales for each product

SELECT p.ProductID, p.ProductName, SUM(oi.Quantity * oi.Price) AS TotalSales
FROM OrderItems oi
JOIN Products p
ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSales DESC;

-- List the top 5 customers by total spending

SELECT CustomerID, FirstName, LastName, TotalSpent, rn
FROM
	(SELECT 
		c.CustomerID, c.FirstName, c.LastName, SUM(o.TotalAmount) AS TotalSpent,
		ROW_NUMBER() OVER (ORDER BY SUM(o.TotalAmount) DESC) AS rn
	FROM Customers c
	JOIN Orders o 
	ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerID, c.FirstName, c.LastName)
sub WHERE rn <= 5;

-- Retrieve the most popular product category

SELECT CategoryID, CategoryName, TotalQuantitySold, rn
FROM
	(SELECT 
		c.CategoryID, c.CategoryName, SUM(oi.Quantity) AS TotalQuantitySold,
		ROW_NUMBER() OVER (ORDER BY SUM(oi.Quantity) DESC) as rn
	FROM OrderItems oi
	JOIN Products p
	ON oi.ProductID = p.ProductID
	JOIN Categories c
	ON p.CategoryID = c.CategoryID
	GROUP BY c.CategoryID, c.CategoryName)
sub WHERE rn = 1;

-- Insert a product with zero stock

INSERT INTO Products(ProductName, CategoryID, Price, Stock)
VALUES ('Keyboard', 1, 39.99, 0);
SELECT * FROM Products;

-- List all products that are out of stock

SELECT p.ProductID, p.ProductName, c.CategoryName, p.Stock
FROM Products p
JOIN Categories c
ON p.CategoryID = c.CategoryID
WHERE Stock = 0;

-- Find customers who placed orders in the last 30 days

SELECT c.CustomerID, c.FirstName, c.LastName, c.Email, c.Phone
FROM Customers c
JOIN Orders o
ON c.CustomerID = o.CustomerID
WHERE o.OrderDate >= DATEADD(DAY, -30, GETDATE());

-- Calculate the total number of orders placed each month

SELECT 
	YEAR(OrderDate) as OrderYear,
	MONTH(OrderDate) as OrderMonth,
	COUNT(OrderID) as TotalOrders
FROM Orders
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY OrderYear, OrderMonth;

-- Retrieve the details of the most recent order

SELECT TOP 1 o.OrderID, o.OrderDate, o.TotalAmount, c.FirstName, c.LastName
FROM Orders o
JOIN Customers c
ON o.CustomerId = c.CustomerID
ORDER BY o.OrderDate DESC;

-- Find the average price of products in each category

SELECT c.CategoryID, c.CategoryName, AVG(p.Price) AS AveragePrice
FROM Categories c
JOIN Products p
ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName;

-- List customers who have never placed an order

SELECT c.CustomerID, c.FirstName, c.LastName, c.Email, c.Phone, o.OrderID, o.TotalAmount
FROM Customers c
LEFT OUTER JOIN Orders o
ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;

-- Retrieve the total quantity sold for each product

SELECT p.ProductID, p.ProductName, SUM(oi.Quantity) AS TotalQuantitySold
FROM OrderItems oi 
JOIN Products p
ON oi.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY p.ProductName;

-- Calculate the total revenue generated from each category

SELECT c.CategoryID, c.CategoryName, SUM(oi.Quantity * oi.Price) AS TotalRevenue
FROM OrderItems oi 
JOIN Products p
ON oi.ProductID = p.ProductID
JOIN Categories c
ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID, c.CategoryName
ORDER BY TotalRevenue DESC;

-- Find the highest-priced product in each category

SELECT c.CategoryID, c.CategoryName, p1.ProductID, p1.ProductName, p1.Price
FROM Categories c
JOIN Products p1
ON c.CategoryID = p1.CategoryID
WHERE p1.Price = (SELECT Max(Price) 
					FROM Products p2 WHERE p2.CategoryID = p1.CategoryID)
ORDER BY p1.Price DESC; 

-- Retrieve orders with a total amount greater than a specific value

SELECT o.OrderID, c.CustomerID, c.FirstName, c.LastName, o.TotalAmount
FROM Orders o
JOIN Customers c
ON o.CustomerID = c.CustomerID
WHERE o.TotalAmount >= 49.99
ORDER BY o.TotalAmount DESC; 

-- List products along with the number of orders appeared in

SELECT p.ProductID, p.ProductName, COUNT(oi.OrderID) as OrderCount
FROM Products p
JOIN OrderItems oi
ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY OrderCount DESC;

-- Find the top 3 most frequently ordered products

SELECT TOP 3 p.ProductID, p.ProductName, COUNT(oi.OrderID) AS OrderCount
FROM OrderItems oi
JOIN Products p
ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY OrderCount DESC;

-- Calculate the total number of customers from each country

SELECT Country, COUNT(CustomerID) as TotalCustomers
FROM Customers
GROUP BY Country 
ORDER BY TotalCustomers DESC;

-- Retrieve the list of customers along with their total spending

SELECT c.CustomerID, c.FirstName, c.LastName, SUM(o.TotalAmount) AS TotalSpending
FROM Customers c 
JOIN Orders o
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.FirstName, c.LastName;

-- List orders with more than a specified number of items

SELECT o.OrderID, c.CustomerID, c.FirstName, c.LastName, COUNT(oi.OrderItemID) AS NumberOfItems
FROM Orders o
JOIN OrderItems oi
ON o.OrderID = oi.OrderID
JOIN Customers c
ON o.CustomerID = c.CustomerID
GROUP BY o.OrderID, c.CustomerID, c.FirstName, c.LastName
HAVING COUNT(oi.OrderItemID) >= 1
ORDER BY NumberOfItems;


-- Log Maintenance 

CREATE TABLE ChangeLog(
					LogID INT PRIMARY KEY IDENTITY(1, 1),
					TableName NVARCHAR(50),
					Operation NVARCHAR(10),
					RecordID INT,
					ChangeDate DATETIME DEFAULT GETDATE(),
					ChangedBy NVARCHAR(100)
					);
GO

-- Trigger for INSERT on Products table

CREATE OR ALTER TRIGGER trg_Insert_Product
ON Products
AFTER INSERT
AS 
BEGIN
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Products', 'INSERT', inserted.ProductID, SYSTEM_USER
	FROM inserted;
	PRINT 'INSERT operation logged for Products table';
END;
GO

INSERT INTO Products(ProductName, CategoryID, Price, Stock)
VALUES ('Wireless Mouse', 1, 4.99, 20);
INSERT INTO Products(ProductName, CategoryID, Price, Stock)
VALUES ('Spiderman Multiverse Comic', 3, 2.50, 150)

SELECT * FROM Products;
SELECT * FROM ChangeLog;

-- Trigger for UPDATE on Products table

CREATE OR ALTER TRIGGER trg_Update_Product
ON Products
AFTER UPDATE
AS
BEGIN
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Products', 'UPDATE', inserted.ProductID, SYSTEM_USER
	FROM inserted;
	PRINT 'UPDATE operation logged for Products table';
END;
GO

UPDATE Products SET Price = Price - 300 WHERE ProductID = 2;

SELECT * FROM Products;
SELECT * FROM ChangeLog;

-- Trigger for DELETE on Products table

CREATE OR ALTER TRIGGER trg_Delete_Product
ON Products
AFTER DELETE
AS 
BEGIN
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Products', 'DELETE', deleted.ProductID, SYSTEM_USER
	FROM deleted;
	PRINT 'DELETE operation logged for Products table';
END;
GO

DELETE FROM Products WHERE ProductID = 11;

SELECT * FROM Products;
SELECT * FROM ChangeLog;

-- Trigger for INSERT on Customers table

CREATE OR ALTER TRIGGER trg_Insert_Customers
ON Customers
AFTER INSERT
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Customers', 'INSERT', inserted.CustomerID, SYSTEM_USER
	FROM inserted;
	PRINT 'INSERT operation logged for Customers table';
END;
GO

INSERT INTO Customers(FirstName, LastName, Country)
VALUES ('Jason', 'Johnson', 'United Kingdom');
INSERT INTO Customers(FirstName, LastName, Country)
VALUES ('Beatrice', 'Bennett', 'France');
INSERT INTO Customers(FirstName, LastName, Email, Phone, Address, City, State, ZipCode, Country)
VALUES ('Virat', 'Kohli', 'virat.kingkohli@example.com', '123-456-7890', 'South Delhi', 'Delhi', 'Delhi', '5456665', 'India');

SELECT * FROM Customers;
SELECT * FROM ChangeLog;

-- Trigger for UPDATE on Customers table

CREATE OR ALTER TRIGGER trg_Update_Customers
ON Customers
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Customers', 'UPDATE', inserted.CustomerID, SYSTEM_USER
	FROM inserted;
	PRINT 'UPDATE operation logged for Customers table';
END;
GO

UPDATE Customers SET State = 'Florida' WHERE State = 'IL';

SELECT * FROM Customers;
SELECT * FROM ChangeLog;

-- Trigger for DELETE on Customers table

CREATE OR ALTER TRIGGER trg_Delete_Customers
ON Customers
AFTER DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	INSERT INTO ChangeLog(TableName, Operation, RecordID, ChangedBy)
	SELECT 'Customers', 'DELETE', deleted.CustomerID, SYSTEM_USER
	FROM deleted;
	PRINT 'DELETE operation logged for Customers table';
END;
GO

DELETE FROM Customers WHERE CustomerID = 5;

SELECT * FROM Customers;
SELECT * FROM ChangeLog;


-- Index Implementation

-- Indexes on Categories table

CREATE CLUSTERED INDEX IDX_Categories_CategoryID
ON Categories(CategoryID);
GO

CREATE CLUSTERED INDEX IDX_Products_ProductID
ON Products(ProductID);
GO

CREATE NONCLUSTERED INDEX IDX_Products_CategoryID
ON Products(CategoryID);
GO

CREATE NONCLUSTERED INDEX IDX_Products_Price
ON Products(Price);
GO

ALTER TABLE OrderItems ADD CONSTRAINT FK_OrderItems_Products
FOREIGN KEY (ProductID) REFERENCES Products(ProductID);
GO

-- Indexes on Orders table

CREATE CLUSTERED INDEX IDX_Orders_OrderID
ON Orders(OrderID);
GO

CREATE NONCLUSTERED INDEX IDX_Orders_CustomerID
ON Orders(CustomerID);
GO

CREATE NONCLUSTERED INDEX IDX_Orders_OrderDate
ON Orders(OrderDate);
GO

ALTER TABLE OrderItems ADD CONSTRAINT FK_OrderItems_OrderID
FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);
GO

-- Indexes on OrderItems table

CREATE CLUSTERED INDEX IDX_OrderItems_OrderItemID
ON OrderItems(OrderItemID);
GO

CREATE NONCLUSTERED INDEX IDX_OrderItems_OrderID
ON OrderItems(OrderID);
GO

CREATE NONCLUSTERED INDEX IDX_OrderItems_ProductID
ON OrderItems(ProductID);
GO

-- Indexes on Customers table

CREATE CLUSTERED INDEX IDX_Customers_CustomerID
ON Customers(CustomerID);
GO

CREATE NONCLUSTERED INDEX IDX_Customers_Email
ON Customers(Email);
GO

CREATE NONCLUSTERED INDEX IDX_Customers_Country
ON Customers(Country);
GO

ALTER TABLE Orders ADD CONSTRAINT FK_Orders_CustomerID
FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);
GO


-- View Implementation

-- View for product details and names of categories

CREATE VIEW vw_ProductDetails 
AS
SELECT p.ProductID, p.ProductName, p.Price, p.Stock, c.CategoryName
FROM Products p 
INNER JOIN Categories c
ON p.CategoryID = c.CategoryID;
GO
SELECT * FROM vw_ProductDetails;

-- View for customer orders placed by each customer

CREATE VIEW vw_CustomerOrders
AS
SELECT 
	c.CustomerID, c.FirstName, c.LastName, 
	COUNT(o.OrderID) AS TotalOrders,
	SUM(oi.Quantity * p.Price) as TotalAmount
FROM Customers c 
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems oi
ON o.OrderID = oi.OrderID
INNER JOIN Products p
ON oi.ProductID = p.ProductID
GROUP BY c.CustomerID, c.FirstName, c.LastName;
GO
SELECT * FROM vw_CustomerOrders;

-- View for displaying recent orders in past 30 days

CREATE VIEW vw_RecentOrders
AS 
SELECT 
	o.OrderID, o.OrderDate, c.CustomerID, c.FirstName, c.LastName,
	SUM(oi.Quantity * oi.Price) AS OrderAmount
FROM Customers c
INNER JOIN Orders o 
ON c.CustomerID = o.CustomerID
INNER JOIN OrderItems oi
ON o.OrderID = oi.OrderID
GROUP BY o.OrderID, o.OrderDate, c.CustomerID, c.FirstName, c.LastName;
GO
SELECT * FROM vw_RecentOrders;


-- Data Analysis

-- Retrieve products within a specific price range

SELECT * FROM vw_ProductDetails
WHERE Price BETWEEN 10 AND 500;

-- Count the number of products falling in each category

SELECT CategoryName, COUNT(ProductID) AS ProductCount
FROM vw_ProductDetails 
GROUP BY CategoryName;

-- Retrieve customers with more than 1 order

SELECT * FROM vw_CustomerOrders
WHERE TotalOrders > 1;

-- Retrieve the total amount spent by each customer

SELECT CustomerID, FirstName, LastName, TotalAmount 
FROM vw_CustomerOrders
ORDER BY TotalAmount DESC;

-- Retrieve recent orders above a certain amount

SELECT * FROM vw_RecentOrders
WHERE OrderAmount > 100;

-- Retrieve the latest order for each customer

SELECT ro.OrderID, ro.OrderDate, ro.CustomerID, ro.FirstName, ro.LastName, ro.OrderAmount
FROM vw_RecentOrders ro
INNER JOIN 
	(SELECT 
		CustomerID, 
		MAX(OrderDate) AS LatestOrderDate
	FROM vw_RecentOrders
	GROUP BY CustomerID) latest
ON ro.CustomerID = latest.CustomerID
AND ro.OrderDate = latest.LatestOrderDate
ORDER BY ro.OrderDate DESC;

-- Retrieve products in a specific category

SELECT * FROM vw_ProductDetails
WHERE CategoryName = 'Books';

-- Retrieve the total sales for each category

SELECT pd.CategoryName, SUM(oi.Quantity * p.Price) AS TotalSales
FROM OrderItems oi
INNER JOIN Products p 
ON oi.ProductID = p.ProductID
INNER JOIN vw_ProductDetails pd
ON p.ProductID = pd.productID
GROUP BY pd.CategoryName
ORDER BY TotalSales DESC;

-- Retrieve customer orders with product details

SELECT 
	co.CustomerID, co.FirstName, co.LastName, o.OrderID, o.OrderDate,
	pd.ProductName, oi.Quantity, pd.Price
FROM Orders o
INNER JOIN OrderItems oi
ON o.OrderID = oi.OrderID
INNER JOIN vw_ProductDetails pd 
ON oi.ProductID = pd.ProductID
INNER JOIN vw_CustomerOrders co
ON o.CustomerID = co.CustomerID
ORDER BY o.OrderDate DESC;

-- Retrieve top 5 customers by total spending

SELECT TOP 5 CustomerID, FirstName, LastName, TotalAmount
FROM vw_CustomerOrders 
ORDER BY TotalAmount DESC;

-- Retrieve products with low stock

SELECT * FROM vw_ProductDetails
WHERE Stock < 50;

-- Retrieve orders placed within the past 7 days

SELECT * FROM vw_RecentOrders
WHERE OrderDate >= DATEADD(DAY, -7, GETDATE());

-- Retrieve all products sold in the past month

SELECT p.ProductID, p.ProductName, SUM(oi.Quantity) AS TotalSold
FROM vw_RecentOrders ro
INNER JOIN OrderItems oi
ON ro.OrderID = oi.OrderID
INNER JOIN Products p
ON oi.ProductID = p.ProductID
WHERE ro.OrderDate >= DATEADD(MONTH, -1, GETDATE())
GROUP BY p.productID, p.ProductName
ORDER BY TotalSold DESC;


-- Security Implementation

CREATE LOGIN SalesUser WITH PASSWORD = 'strongpassword';

USE digital_retail_firm_analysis;
GO

CREATE USER SalesUser FOR LOGIN SalesUser;

CREATE ROLE SalesRole;
CREATE ROLE MarketingRole;

EXEC sp_addrolemember 'SalesRole', 'SalesUser';

GRANT SELECT ON Customers TO SalesRole;
GRANT INSERT ON Orders TO SalesRole;
GRANT UPDATE ON Orders TO SalesRole;
GRANT SELECT ON Products TO SalesRole;

REVOKE INSERT ON Orders FROM SalesRole;

SELECT * FROM fn_my_permissions(NULL, 'DATABASE');

-- Data Entry Clerk - INSERT Access on Orders and OrderItems

CREATE ROLE DataEntryClerk;
GRANT INSERT ON Orders TO DataEntryClerk;
GRANT INSERT ON OrderItems TO DataEntryClerk;

-- Product Manager - Full Access to Products and Categories

CREATE ROLE ProductManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Products TO ProductManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Categories TO ProductManagerRole;

-- Order Processor - Read and UPDATE Access on Orders

CREATE ROLE OrderProcessorRole;
GRANT SELECT, UPDATE ON Orders TO OrderProcessorRole;

-- Customer Support - Read Access to Customers and Orders

CREATE ROLE CustomerSupportRole;
GRANT SELECT ON Customers TO CustomerSupportRole;
GRANT SELECT ON Orders TO CustomerSupportRole;

-- Marketing Analyst - Read Access to Complete Tables

CREATE ROLE MarketingAnalystRole;
GRANT SELECT ON SCHEMA::dbo TO MarketingAnalystRole

-- Sales Analyst - Read Access to Orders and OrderItems

CREATE ROLE SalesAnalystRole;
GRANT SELECT ON Orders TO SalesAnalystRole;
GRANT SELECT ON OrderItems TO SalesAnalyst

-- Inventory Manager - Complete Access to Products

CREATE ROLE InventoryManagerRole;
GRANT SELECT, INSERT, UPDATE, DELETE ON Products TO InventoryManagerRole;

-- Finance Manager - Read and UPDATE Access on Orders

CREATE ROLE FinanceManagerRole;
GRANT SELECT, UPDATE ON Orders TO FinanceManagerRole;

-- Database Backup Operator - Backup Access on Database

CREATE ROLE BackupOperatorRole;
GRANT BACKUP DATABASE TO BackupOperatorRole;

-- Database Developer - Complete Access to Schema Objects

CREATE ROLE DatabaseDeveloperRole;
GRANT CREATE TABLE TO DatabaseDeveloperRole;
GRANT ALTER ON SCHEMA::dbo TO DatabaseDeveloperRole;
GRANT SELECT ON SCHEMA::dbo TO DatabaseDeveloperRole;

-- General Analyst - Restricted Read Access

CREATE ROLE GeneralAnalyst;
GRANT SELECT (FirstName, LastName, Email) ON Customers TO GeneralAnalyst;

-- Reporting User - Read Access to Views

CREATE ROLE ReportingUserRole;
GRANT SELECT ON vw_CustomerOrders TO ReportingUserRole;
GRANT SELECT ON vw_ProductDetails TO ReportingUserRole;
GRANT SELECT ON vw_RecentOrders TO ReportingUserRole;

-- Intern - Time-Bound Access

CREATE ROLE InternRole;
GRANT SELECT ON SCHEMA::dbo TO InternRole;
REVOKE SELECT ON SCHEMA::dbo FROM InternRole;

-- External Auditor - Read Access

CREATE ROLE AuditorRole;
GRANT SELECT ON SCHEMA::dbo TO AuditorRole;
DENY INSERT, UPDATE, DELETE ON SCHEMA::dbo TO AuditorRole;

-- Application Role - Application-Based Access

CREATE APPLICATION ROLE ApplicationRole WITH PASSWORD = 'StrongPassword1';
GRANT SELECT, INSERT, UPDATE ON Orders TO ApplicationRole;

-- Role-Based Access Control for Multiple Roles

CREATE ROLE CombinedRole;
EXEC sp_addrolemember 'SalesRole', 'CombinedRole';
EXEC sp_addrolemember 'MarketingRole', 'CombinedRole';

-- Junior Analyst - Sensitive Access to Columns

CREATE ROLE JuniorAnalyst;
GRANT SELECT (Email, Phone) ON Customers TO JuniorAnalyst;

-- Database Manager - Complete Access to Development Database

CREATE ROLE DatabaseManager;
GRANT CONTROL ON DATABASE::digital_retail_firm_analysis TO DatabaseManager;

-- Security Administrator - Security Privileges Access

CREATE ROLE SecurityAdministratorRole;
GRANT ALTER ANY USER TO SecurityAdministratorRole;
GRANT ALTER ANY LOGIN TO SecurityAdministratorRole;
GRANT ALTER ANY ROLE TO SecurityAdministratorRole;