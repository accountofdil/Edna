-- Database Creation

CREATE DATABASE ecommerce_management_system; 
USE ecommerce_management_system;
SELECT DATABASE();

DROP TABLE IF EXISTS Categories;
DROP TABLE IF EXISTS Sellers;
DROP TABLE IF EXISTS Customers;
DROP TABLE IF EXISTS Products;
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Cart;
DROP TABLE IF EXISTS Order_Items;
DROP TABLE IF EXISTS Payments;
DROP TABLE IF EXISTS Shipments;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Return_Requests;

CREATE TABLE Categories(
					CategoryID INT PRIMARY KEY AUTO_INCREMENT,
                    CategoryName VARCHAR(50) NOT NULL);

CREATE TABLE Sellers(
				SellerID INT PRIMARY KEY AUTO_INCREMENT,
                SellerName VARCHAR(100) NOT NULL, 
                Email VARCHAR(50),
                Phone VARCHAR(50), 
                Address VARCHAR(100));

CREATE TABLE Customers(
					CustomerID INT PRIMARY KEY AUTO_INCREMENT,
                    CustomerName VARCHAR(50),
                    Email VARCHAR(50) UNIQUE,
                    Phone VARCHAR(50),
                    Address VARCHAR(100),
                    RegisterDate DATE);

CREATE TABLE Products(
					ProductID INT PRIMARY KEY AUTO_INCREMENT,
                    ProductName VARCHAR(50) NOT NULL,
                    CategoryID INT,
                    SellerID INT, 
                    Price DECIMAL(10, 2) NOT NULL, 
                    Description VARCHAR(50),
                    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
                    FOREIGN KEY (SellerID) REFERENCES Sellers(SellerID));

CREATE TABLE Inventory(
					InventoryID INT PRIMARY KEY AUTO_INCREMENT,
                    ProductID INT, 
                    StockQuantity INT NOT NULL,
                    LastUpdated DATE, 
                    FOREIGN KEY (ProductID) REFERENCES Products(ProductID));

CREATE TABLE Orders(
				OrderID INT PRIMARY KEY AUTO_INCREMENT,
                CustomerID INT, 
                OrderDate DATE, 
                TotalAmount DECIMAL(10, 2),
                OrderStatus VARCHAR(20),
                FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID));

CREATE TABLE Cart(
				CartID INT PRIMARY KEY AUTO_INCREMENT,
                CustomerID INT,
                ProductID INT,
                Quantity INT,
                AddedDate DATE,
                FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
                FOREIGN KEY (ProductID) REFERENCES Products(ProductID));

CREATE TABLE Order_Items(
						OrderItemID INT PRIMARY KEY AUTO_INCREMENT, 
                        OrderID INT, 
                        ProductID INT,
                        Quantity INT,
                        Price DECIMAL(10, 2),
                        FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
                        FOREIGN KEY (ProductID) REFERENCES Products(ProductID));

CREATE TABLE Payments(
					PaymentID INT PRIMARY KEY AUTO_INCREMENT,
                    OrderID INT,
                    PaymentDate DATE, 
                    Amount DECIMAL(10, 2),
                    PaymentMethod VARCHAR(20),
                    PaymentStatus VARCHAR(20),
                    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID));

CREATE TABLE Shipments(
					ShipmentID INT PRIMARY KEY AUTO_INCREMENT, 
                    OrderID INT,
                    ShipDate DATE, 
                    DeliveryDate DATE,
                    ShipmentStatus VARCHAR(20),
                    Courier VARCHAR(50),
                    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID));

CREATE TABLE Reviews(
					ReviewID INT PRIMARY KEY AUTO_INCREMENT, 
                    CustomerID INT,
                    ProductID INT,
                    Rating INT CHECK(Rating BETWEEN 1 AND 5),
                    Comment VARCHAR(250),
                    ReviewDate DATE,
                    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
                    FOREIGN KEY (ProductID) REFERENCES Products(ProductID));

CREATE TABLE Return_Requests(
							ReturnID INT PRIMARY KEY AUTO_INCREMENT,
                            OrderID INT,
                            ReturnReason VARCHAR(100),
                            ReturnDate DATE,
                            ReturnStatus VARCHAR(20),
                            FOREIGN KEY (OrderID) REFERENCES Orders(OrderID));
                            
INSERT INTO Categories(CategoryName)
VALUES
('Electronics'),
('Mobile Phones'),
('Laptops'),
('Home Appliances'),
('Furniture'),
('Clothing'),
('Footwear'),
('Books'),
('Toys'),
('Beauty & Personal Care'),
('Sports & Fitness'),
('Groceries'),
('Kitchenware'),
('Stationery'),
('Watches & Accessories'),
('Pet Supplies'),
('Musical Instruments'),
('Automotive'),
('Health & Wellness'),
('Garden & Outdoor');

SELECT * FROM Categories;

INSERT INTO Sellers(SellerName, Email, Phone, Address)
VALUES
('TechWorld Traders', 'techworld@mail.com', '9000000001', 'Chennai'),
('Gadget Hub', 'gadgethub@mail.com', '9000000002', 'Bangalore'),
('HomeStyle Mart', 'homestyle@mail.com', '9000000003', 'Coimbatore'),
('FashionPoint', 'fashionpoint@mail.com', '9000000004', 'Mumbai'),
('SportyZone', 'sportyzone@mail.com', '9000000005', 'Delhi'),
('BookHaven', 'bookhaven@mail.com', '9000000006', 'Hyderabad'),
('GlowBeauty', 'glowbeauty@mail.com', '9000000007', 'Pune'),
('KidsLand Toys', 'kidsland@mail.com', '9000000008', 'Kolkata'),
('FreshGrocers', 'freshgrocers@mail.com', '9000000009', 'Chennai'),
('ElectroMax', 'electromax@mail.com', '9000000010', 'Bangalore'),
('StyleHub Footwear', 'stylehub@mail.com', '9000000011', 'Madurai'),
('SmartLiving', 'smartliving@mail.com', '9000000012', 'Trichy'),
('AppliancePro', 'appliancepro@mail.com', '9000000013', 'Salem'),
('UrbanThreads', 'urbanthreads@mail.com', '9000000014', 'Vellore'),
('FitGear', 'fitgear@mail.com', '9000000015', 'Erode'),
('KitchenKraft', 'kitchenkraft@mail.com', '9000000016', 'Coimbatore'),
('PetCare Plus', 'petcareplus@mail.com', '9000000017', 'Pune'),
('MusicMart', 'musicmart@mail.com', '9000000018', 'Chennai'),
('AutoZone Parts', 'autozone@mail.com', '9000000019', 'Mumbai'),
('WellnessHub', 'wellnesshub@mail.com', '9000000020', 'Bangalore'),
('GardenGreens', 'gardengreens@mail.com', '9000000021', 'Trichy'),
('WriteRight Stationery', 'writeright@mail.com', '9000000022', 'Madurai'),
('TimeTrend Watches', 'timetrend@mail.com', '9000000023', 'Delhi'),
('MegaMart Electronics', 'megamart@mail.com', '9000000024', 'Hyderabad'),
('DailyNeeds Grocers', 'dailyneeds@mail.com', '9000000025', 'Chennai');

SELECT COUNT(SellerID) FROM Sellers;
SELECT * FROM Sellers;

INSERT INTO Customers(CustomerName, Email, Phone, Address, RegisterDate)
VALUES
('Arun Kumar', 'arun1@mail.com', '9100000001', 'Chennai', '2023-01-05'),
('Priya Sharma', 'priya2@mail.com', '9100000002', 'Mumbai', '2023-01-10'),
('Rahul Verma', 'rahul3@mail.com', '9100000003', 'Delhi', '2023-01-15'),
('Sneha Reddy', 'sneha4@mail.com', '9100000004', 'Hyderabad', '2023-01-20'),
('Vikram Singh', 'vikram5@mail.com', '9100000005', 'Bangalore', '2023-01-25'),
('Anjali Nair', 'anjali6@mail.com', '9100000006', 'Kochi', '2023-02-01'),
('Karthik Raja', 'karthik7@mail.com', '9100000007', 'Coimbatore', '2023-02-05'),
('Divya Menon', 'divya8@mail.com', '9100000008', 'Trivandrum', '2023-02-10'),
('Manoj Pillai', 'manoj9@mail.com', '9100000009', 'Madurai', '2023-02-15'),
('Lakshmi Iyer', 'lakshmi10@mail.com', '9100000010', 'Pune', '2023-02-20'),
('Suresh Babu', 'suresh11@mail.com', '9100000011', 'Salem', '2023-02-25'),
('Pooja Patel', 'pooja12@mail.com', '9100000012', 'Ahmedabad', '2023-03-01'),
('Ramesh Gupta', 'ramesh13@mail.com', '9100000013', 'Jaipur', '2023-03-05'),
('Kavya Krishnan', 'kavya14@mail.com', '9100000014', 'Trichy', '2023-03-10'),
('Arjun Das', 'arjun15@mail.com', '9100000015', 'Kolkata', '2023-03-15'),
('Meena Rajan', 'meena16@mail.com', '9100000016', 'Vellore', '2023-03-20'),
('Naveen Kumar', 'naveen17@mail.com', '9100000017', 'Erode', '2023-03-25'),
('Swathi Reddy', 'swathi18@mail.com', '9100000018', 'Vijayawada', '2023-04-01'),
('Harish Chandra', 'harish19@mail.com', '9100000019', 'Nagpur', '2023-04-05'),
('Deepa Suresh', 'deepa20@mail.com', '9100000020', 'Chennai', '2023-04-10'),
('Vijay Anand', 'vijay21@mail.com', '9100000021', 'Mumbai', '2023-04-15'),
('Nisha Thomas', 'nisha22@mail.com', '9100000022', 'Kochi', '2023-04-20'),
('Sanjay Mehta', 'sanjay23@mail.com', '9100000023', 'Delhi', '2023-04-25'),
('Geetha Bhat', 'geetha24@mail.com', '9100000024', 'Mangalore', '2023-05-01'),
('Praveen Kumar', 'praveen25@mail.com', '9100000025', 'Hyderabad', '2023-05-05'),
('Anitha Rao', 'anitha26@mail.com', '9100000026', 'Bangalore', '2023-05-10'),
('Dinesh Karthik', 'dinesh27@mail.com', '9100000027', 'Chennai', '2023-05-15'),
('Sandhya Pillai', 'sandhya28@mail.com', '9100000028', 'Trivandrum', '2023-05-20'),
('Mohan Das', 'mohan29@mail.com', '9100000029', 'Coimbatore', '2023-05-25'),
('Revathi Nair', 'revathi30@mail.com', '9100000030', 'Kochi', '2023-06-01'),
('Ajay Singh', 'ajay31@mail.com', '9100000031', 'Lucknow', '2023-06-05'),
('Bhavana Reddy', 'bhavana32@mail.com', '9100000032', 'Hyderabad', '2023-06-10'),
('Chandru Vel', 'chandru33@mail.com', '9100000033', 'Madurai', '2023-06-15'),
('Devika Menon', 'devika34@mail.com', '9100000034', 'Trichy', '2023-06-20'),
('Eswari Pandian', 'eswari35@mail.com', '9100000035', 'Salem', '2023-06-25'),
('Faizal Ahmed', 'faizal36@mail.com', '9100000036', 'Bangalore', '2023-07-01'),
('Gokul Raj', 'gokul37@mail.com', '9100000037', 'Chennai', '2023-07-05'),
('Hema Latha', 'hema38@mail.com', '9100000038', 'Vellore', '2023-07-10'),
('Indra Kumar', 'indra39@mail.com', '9100000039', 'Erode', '2023-07-15'),
('Jyothi Rani', 'jyothi40@mail.com', '9100000040', 'Pune', '2023-07-20'),
('Kiran Babu', 'kiran41@mail.com', '9100000041', 'Mumbai', '2023-07-25'),
('Latha Subramani', 'latha42@mail.com', '9100000042', 'Coimbatore', '2023-08-01'),
('Manikandan S', 'manikandan43@mail.com', '9100000043', 'Tirupur', '2023-08-05'),
('Nandhini R', 'nandhini44@mail.com', '9100000044', 'Chennai', '2023-08-10'),
('Omkar Joshi', 'omkar45@mail.com', '9100000045', 'Nagpur', '2023-08-15'),
('Pavithra K', 'pavithra46@mail.com', '9100000046', 'Madurai', '2023-08-20'),
('Qadir Khan', 'qadir47@mail.com', '9100000047', 'Hyderabad', '2023-08-25'),
('Ranjini S', 'ranjini48@mail.com', '9100000048', 'Bangalore', '2023-09-01'),
('Suresh Kannan', 'sureshk49@mail.com', '9100000049', 'Salem', '2023-09-05'),
('Tanvi Shah', 'tanvi50@mail.com', '9100000050', 'Ahmedabad', '2023-09-10'),
('Uday Kiran', 'uday51@mail.com', '9100000051', 'Vijayawada', '2023-09-15'),
('Vasanthi M', 'vasanthi52@mail.com', '9100000052', 'Trichy', '2023-09-20'),
('Wilson Raj', 'wilson53@mail.com', '9100000053', 'Kochi', '2023-09-25'),
('Yamini Devi', 'yamini54@mail.com', '9100000054', 'Chennai', '2023-10-01'),
('Zafar Ali', 'zafar55@mail.com', '9100000055', 'Mumbai', '2023-10-05'),
('Abinaya R', 'abinaya56@mail.com', '9100000056', 'Coimbatore', '2023-10-10'),
('Balaji T', 'balaji57@mail.com', '9100000057', 'Madurai', '2023-10-15'),
('Chitra V', 'chitra58@mail.com', '9100000058', 'Trivandrum', '2023-10-20'),
('Deepak Sharma', 'deepak59@mail.com', '9100000059', 'Delhi', '2023-10-25'),
('Esha Kapoor', 'esha60@mail.com', '9100000060', 'Bangalore', '2023-10-30');

SELECT COUNT(CustomerID) FROM Customers;
SELECT * FROM Customers;

INSERT INTO Products(ProductName, CategoryID, SellerID, Price, Description)
VALUES
('Samsung Galaxy M14', 2, 2, 12999.00, 'Smartphone with 6.6 inch display'),
('Redmi Note 13', 2, 10, 15999.00, 'Smartphone with 108MP camera'),
('Apple iPhone 13', 2, 24, 54999.00, '128GB storage smartphone'),
('Dell Inspiron 15', 3, 1, 45999.00, 'Laptop with i5 processor'),
('HP Pavilion 14', 3, 24, 52999.00, 'Laptop with Ryzen 5'),
('Lenovo IdeaPad 3', 3, 2, 39999.00, 'Laptop with 8GB RAM'),
('Sony Bluetooth Headphones', 1, 2, 2999.00, 'Wireless over-ear headphones'),
('boAt Smartwatch', 15, 23, 1999.00, 'Fitness tracking smartwatch'),
('Titan Watch Classic', 15, 23, 3499.00, 'Analog wrist watch'),
('LG 32 inch LED TV', 1, 24, 18999.00, 'HD smart television'),
('Samsung Microwave Oven', 4, 13, 8999.00, '23L convection microwave'),
('Philips Air Fryer', 4, 13, 6999.00, '4.1L digital air fryer'),
('Prestige Mixer Grinder', 4, 13, 3299.00, '750W mixer grinder'),
('Wooden Study Table', 5, 3, 5999.00, 'Engineered wood study table'),
('Office Chair Ergonomic', 5, 12, 7499.00, 'Adjustable mesh office chair'),
('Sofa Set 3 Seater', 5, 12, 24999.00, 'Fabric sofa with cushions'),
('Cotton Bedsheet Set', 5, 3, 1299.00, 'King size bedsheet with pillow covers'),
('Men Casual Shirt', 6, 4, 999.00, 'Cotton casual shirt'),
('Women Kurti', 6, 14, 799.00, 'Printed cotton kurti'),
('Men Jeans Slim Fit', 6, 4, 1499.00, 'Stretchable denim jeans'),
('Women Saree Silk', 6, 14, 2999.00, 'Traditional silk saree'),
('Kids T-Shirt Pack', 6, 14, 599.00, 'Pack of 3 cotton t-shirts'),
('Nike Running Shoes', 7, 11, 3999.00, 'Lightweight running shoes'),
('Adidas Sports Sandals', 7, 11, 1499.00, 'Comfortable sports sandals'),
('Bata Formal Shoes', 7, 11, 2499.00, 'Leather formal shoes'),
('Women Heels', 7, 11, 1799.00, 'Party wear heels'),
('The Alchemist Book', 8, 6, 399.00, 'Bestselling fiction novel'),
('Atomic Habits', 8, 6, 499.00, 'Self-help book'),
('SQL for Beginners', 8, 6, 599.00, 'Database programming guide'),
('NCERT Maths Class 10', 8, 6, 250.00, 'School textbook'),
('Lego Building Blocks', 9, 8, 1999.00, 'Creative building set for kids'),
('Remote Control Car', 9, 8, 1299.00, 'Rechargeable RC car'),
('Barbie Doll Set', 9, 8, 899.00, 'Doll with accessories'),
('Puzzle Game 500pcs', 9, 8, 599.00, 'Cardboard jigsaw puzzle'),
('Lakme Lipstick', 10, 7, 499.00, 'Matte finish lipstick'),
('Nivea Face Cream', 10, 7, 299.00, 'Moisturizing face cream'),
('Dove Shampoo 650ml', 10, 7, 399.00, 'Nourishing shampoo'),
('Mens Perfume 100ml', 10, 7, 1299.00, 'Long lasting fragrance'),
('Yoga Mat', 11, 5, 799.00, 'Anti-skid exercise mat'),
('Dumbbell Set 10kg', 11, 5, 2499.00, 'Pair of rubber dumbbells'),
('Cricket Bat', 11, 5, 1999.00, 'English willow bat'),
('Football Size 5', 11, 5, 899.00, 'Standard size football'),
('Basmati Rice 5kg', 12, 9, 599.00, 'Premium basmati rice'),
('Sunflower Oil 1L', 12, 9, 159.00, 'Refined sunflower oil'),
('Toor Dal 1kg', 12, 9, 139.00, 'Unpolished toor dal'),
('Tea Powder 500g', 12, 25, 249.00, 'Strong CTC tea'),
('Non-stick Frying Pan', 13, 16, 899.00, '26cm non-stick pan'),
('Steel Lunch Box', 13, 16, 449.00, '3 compartment lunch box'),
('Glass Water Bottle Set', 13, 16, 599.00, 'Set of 2 borosilicate bottles'),
('Notebook Pack of 5', 14, 22, 250.00, 'Ruled notebooks 200 pages'),
('Gel Pen Pack of 10', 14, 22, 99.00, 'Smooth writing gel pens'),
('Art Color Set', 14, 22, 349.00, '24 shades sketch pens'),
('Dog Food 3kg', 16, 17, 1199.00, 'Dry dog food chicken flavor'),
('Cat Litter Box', 16, 17, 699.00, 'Plastic litter tray'),
('Acoustic Guitar', 17, 18, 4999.00, '6 string acoustic guitar'),
('Digital Keyboard Piano', 17, 18, 7999.00, '61 key keyboard'),
('Car Phone Holder', 18, 19, 399.00, 'Dashboard mobile mount'),
('Car Vacuum Cleaner', 18, 19, 1499.00, 'Portable car vacuum'),
('Protein Powder 1kg', 19, 20, 1999.00, 'Whey protein chocolate flavor'),
('Multivitamin Tablets', 19, 20, 599.00, '60 tablets bottle'),
('Garden Hose 10m', 20, 21, 899.00, 'Flexible water hose');

SELECT COUNT(ProductID) FROM Products;

SELECT 
	ProductName, 
	COUNT(*) 
FROM PRODUCTS
GROUP BY ProductName
HAVING COUNT(*) > 1;

SELECT * FROM Products;

INSERT INTO Inventory(ProductID, StockQuantity, LastUpdated)
SELECT ProductID, FLOOR(10 + RAND() * 90), DATE_SUB(CURDATE(), INTERVAL FLOOR(RAND() * 60) DAY) FROM Products;
SELECT COUNT(InventoryID) FROM Inventory;
SELECT * FROM Inventory;

INSERT INTO Orders(CustomerID, OrderDate, TotalAmount, OrderStatus)
VALUES
(3, '2025-06-20', 2499.00, 'Delivered'),
(7, '2025-06-26', 5999.00, 'Delivered'),
(12, '2025-07-02', 1299.00, 'Cancelled'),
(3, '2025-07-08', 8999.00, 'Delivered'),
(19, '2025-07-14', 399.00, 'Delivered'),
(25, '2025-07-20', 12999.00, 'Shipped'),
(8, '2025-07-26', 1999.00, 'Delivered'),
(31, '2025-08-01', 799.00, 'Pending'),
(7, '2025-08-07', 3499.00, 'Delivered'),
(45, '2025-08-13', 54999.00, 'Delivered'),
(2, '2025-08-19', 999.00, 'Cancelled'),
(50, '2025-08-25', 2999.00, 'Delivered'),
(12, '2025-08-31', 4999.00, 'Shipped'),
(33, '2025-09-06', 1499.00, 'Delivered'),
(19, '2025-09-12', 6999.00, 'Pending'),
(41, '2025-09-18', 899.00, 'Delivered'),
(5, '2025-09-24', 45999.00, 'Delivered'),
(56, '2025-09-30', 599.00, 'Cancelled'),
(3, '2025-10-06', 2499.00, 'Delivered'),
(28, '2025-10-12', 7999.00, 'Shipped'),
(14, '2025-10-18', 1799.00, 'Delivered'),
(60, '2025-10-24', 399.00, 'Delivered'),
(7, '2025-10-30', 15999.00, 'Pending'),
(22, '2025-11-05', 599.00, 'Delivered'),
(35, '2025-11-11', 249.00, 'Cancelled'),
(45, '2025-11-17', 18999.00, 'Delivered'),
(9, '2025-11-23', 3299.00, 'Shipped'),
(18, '2025-11-29', 1299.00, 'Delivered'),
(50, '2025-12-05', 24999.00, 'Delivered'),
(27, '2025-12-11', 499.00, 'Pending'),
(12, '2025-12-17', 899.00, 'Delivered'),
(38, '2025-12-23', 7499.00, 'Delivered'),
(44, '2025-12-29', 159.00, 'Cancelled'),
(3, '2026-01-04', 39999.00, 'Delivered'),
(52, '2026-01-10', 1999.00, 'Shipped'),
(15, '2026-01-16', 699.00, 'Delivered'),
(7, '2026-01-22', 4999.00, 'Delivered'),
(29, '2026-01-28', 250.00, 'Pending'),
(58, '2026-02-03', 1199.00, 'Delivered'),
(40, '2026-02-09', 599.00, 'Delivered'),
(19, '2026-02-15', 2999.00, 'Cancelled'),
(11, '2026-02-21', 449.00, 'Delivered'),
(45, '2026-02-27', 52999.00, 'Shipped'),
(33, '2026-03-05', 999.00, 'Delivered'),
(24, '2026-03-11', 1499.00, 'Delivered'),
(50, '2026-03-17', 399.00, 'Pending'),
(6, '2026-03-23', 6999.00, 'Delivered'),
(48, '2026-03-29', 139.00, 'Delivered'),
(3, '2026-04-04', 12999.00, 'Cancelled'),
(21, '2026-04-10', 8999.00, 'Delivered'),
(37, '2026-04-16', 1999.00, 'Shipped'),
(12, '2026-04-22', 349.00, 'Delivered'),
(45, '2026-04-28', 2499.00, 'Delivered'),
(54, '2026-05-04', 99.00, 'Pending'),
(7, '2026-05-10', 1299.00, 'Delivered'),
(30, '2026-05-16', 799.00, 'Delivered'),
(59, '2026-05-22', 3999.00, 'Cancelled'),
(3, '2026-05-28', 599.00, 'Delivered'),
(45, '2026-06-03', 24999.00, 'Shipped'),
(17, '2026-06-09', 1799.00, 'Delivered');

SELECT COUNT(OrderID) FROM Orders;
SELECT * FROM Orders;

INSERT INTO Cart(CustomerID, ProductID, Quantity, AddedDate)
VALUES
(1, 5, 1, '2026-06-01'),
(1, 23, 2, '2026-06-01'),
(2, 12, 2, '2026-06-02'),
(4, 23, 1, '2026-06-02'),
(5, 8, 3, '2026-06-03'),
(5, 41, 1, '2026-06-03'),
(6, 30, 1, '2026-06-03'),
(9, 45, 1, '2026-06-04'),
(9, 19, 1, '2026-06-04'),
(10, 19, 2, '2026-06-04'),
(11, 2, 1, '2026-06-05'),
(13, 55, 1, '2026-06-05'),
(13, 33, 2, '2026-06-05'),
(14, 33, 2, '2026-06-06'),
(15, 7, 1, '2026-06-06'),
(16, 41, 1, '2026-06-07'),
(17, 26, 3, '2026-06-07'),
(17, 60, 1, '2026-06-07'),
(18, 60, 1, '2026-06-08'),
(20, 14, 2, '2026-06-08'),
(20, 38, 1, '2026-06-08'),
(21, 38, 1, '2026-06-09'),
(22, 9, 1, '2026-06-09'),
(23, 50, 2, '2026-06-10'),
(23, 4, 1, '2026-06-10'),
(24, 4, 1, '2026-06-10'),
(26, 17, 1, '2026-06-10'),
(27, 22, 2, '2026-06-11'),
(28, 31, 1, '2026-06-11'),
(29, 6, 1, '2026-06-11'),
(30, 48, 3, '2026-06-12'),
(30, 11, 1, '2026-06-12'),
(31, 11, 1, '2026-06-12'),
(32, 53, 1, '2026-06-12'),
(34, 25, 2, '2026-06-12'),
(36, 39, 1, '2026-06-13'),
(37, 16, 1, '2026-06-13'),
(37, 44, 1, '2026-06-13'),
(39, 44, 2, '2026-06-13'),
(40, 21, 1, '2026-06-13'),
(41, 58, 1, '2026-06-14'),
(42, 3, 2, '2026-06-14'),
(42, 35, 1, '2026-06-14'),
(43, 35, 1, '2026-06-14'),
(44, 29, 1, '2026-06-14'),
(45, 13, 3, '2026-06-14'),
(46, 47, 1, '2026-06-14'),
(47, 10, 1, '2026-06-14'),
(48, 56, 2, '2026-06-15'),
(48, 24, 1, '2026-06-15'),
(49, 24, 1, '2026-06-15'),
(50, 1, 1, '2026-06-15'),
(51, 42, 1, '2026-06-15'),
(52, 18, 2, '2026-06-15'),
(53, 36, 1, '2026-06-15');

SELECT COUNT(CartID) FROM Cart;
SELECT * FROM Cart;

SELECT 
	CustomerID,
    COUNT(*)
FROM CART
GROUP BY CustomerID
HAVING COUNT(*) > 1;

INSERT INTO Order_Items(OrderID, ProductID, Quantity, Price)
VALUES
(1, 61, 1, 899.00),
(1, 10, 2, 18999.00),
(2, 5, 2, 52999.00),
(3, 7, 1, 2999.00),
(4, 38, 2, 1299.00),
(4, 4, 1, 45999.00),
(5, 6, 1, 39999.00),
(6, 5, 1, 52999.00),
(6, 16, 2, 24999.00),
(7, 4, 2, 45999.00),
(7, 53, 1, 1199.00),
(8, 41, 2, 1999.00),
(9, 61, 2, 899.00),
(9, 4, 1, 45999.00),
(9, 37, 1, 399.00),
(10, 3, 2, 54999.00),
(11, 55, 1, 4999.00),
(12, 19, 1, 799.00),
(13, 35, 1, 499.00),
(14, 20, 2, 1499.00),
(14, 36, 1, 299.00),
(14, 53, 1, 1199.00),
(15, 37, 1, 399.00),
(15, 41, 1, 1999.00),
(15, 13, 2, 3299.00),
(16, 37, 1, 399.00),
(17, 14, 2, 5999.00),
(17, 32, 1, 1299.00),
(17, 44, 1, 159.00),
(18, 30, 1, 250.00),
(19, 60, 1, 599.00),
(19, 30, 1, 250.00),
(19, 24, 1, 1499.00),
(20, 6, 2, 39999.00),
(21, 34, 1, 599.00),
(21, 32, 2, 1299.00),
(22, 19, 1, 799.00),
(22, 39, 1, 799.00),
(23, 27, 1, 399.00),
(23, 11, 1, 8999.00),
(23, 49, 1, 599.00),
(24, 3, 1, 54999.00),
(24, 43, 2, 599.00),
(25, 37, 1, 399.00),
(26, 22, 1, 599.00),
(26, 45, 2, 139.00),
(27, 38, 1, 1299.00),
(27, 52, 1, 349.00),
(28, 61, 1, 899.00),
(29, 45, 1, 139.00),
(29, 43, 1, 599.00),
(30, 42, 2, 899.00),
(30, 37, 1, 399.00),
(31, 46, 2, 249.00),
(31, 25, 1, 2499.00),
(32, 61, 1, 899.00),
(33, 23, 1, 3999.00),
(34, 40, 1, 2499.00),
(35, 4, 1, 45999.00),
(35, 14, 1, 5999.00),
(36, 26, 1, 1799.00),
(37, 6, 1, 39999.00),
(37, 11, 1, 8999.00),
(38, 18, 1, 999.00),
(38, 57, 2, 399.00),
(38, 9, 1, 3499.00),
(39, 23, 1, 3999.00),
(39, 44, 1, 159.00),
(40, 6, 1, 39999.00),
(41, 10, 1, 18999.00),
(42, 43, 1, 599.00),
(43, 32, 2, 1299.00),
(44, 17, 1, 1299.00),
(45, 10, 1, 18999.00),
(46, 24, 1, 1499.00),
(46, 40, 1, 2499.00),
(46, 37, 2, 399.00),
(47, 61, 2, 899.00),
(47, 40, 2, 2499.00),
(47, 42, 1, 899.00),
(48, 58, 2, 1499.00),
(48, 56, 2, 7999.00),
(49, 26, 1, 1799.00),
(50, 26, 1, 1799.00),
(50, 7, 2, 2999.00),
(51, 4, 1, 45999.00),
(51, 13, 1, 3299.00),
(52, 11, 1, 8999.00),
(52, 8, 2, 1999.00),
(53, 7, 1, 2999.00),
(54, 10, 1, 18999.00),
(54, 35, 2, 499.00),
(54, 7, 1, 2999.00),
(55, 56, 1, 7999.00),
(56, 25, 1, 2499.00),
(56, 10, 1, 18999.00),
(56, 41, 2, 1999.00),
(57, 24, 1, 1499.00),
(58, 8, 1, 1999.00),
(58, 55, 1, 4999.00),
(59, 31, 1, 1999.00),
(59, 20, 1, 1499.00),
(60, 48, 1, 449.00);

SELECT COUNT(OrderItemID) FROM Order_Items;
SELECT * FROM Order_Items;

SELECT 
	OrderID,
    SUM(Quantity * Price) AS RealTotal
FROM Order_Items
GROUP BY OrderID;

SET SQL_SAFE_UPDATES = 0;
UPDATE Orders AS o
SET TotalAmount = (SELECT COALESCE(SUM(oi.Quantity * oi.Price), 0) 
					FROM Order_Items AS oi
					WHERE oi.OrderID = o.OrderID);

SELECT 
	OrderID, 
    TotalAmount
FROM Orders
ORDER BY OrderID;

SELECT * FROM Orders;

INSERT INTO Payments(OrderID, PaymentDate, Amount, PaymentMethod, PaymentStatus)
VALUES
(1, '2025-06-21', 38897.00, 'Credit Card', 'Success'),
(2, '2025-06-27', 105998.00, 'Net Banking', 'Success'),
(3, '2025-07-04', 2999.00, 'Debit Card', 'Refunded'),
(4, '2025-07-08', 48597.00, 'Credit Card', 'Success'),
(5, '2025-07-15', 39999.00, 'Credit Card', 'Success'),
(6, '2025-07-22', 102997.00, 'Credit Card', 'Success'),
(7, '2025-07-26', 93197.00, 'Net Banking', 'Success'),
(8, '2025-08-02', 3998.00, 'UPI', 'Success'),
(9, '2025-08-09', 48196.00, 'Credit Card', 'Success'),
(10, '2025-08-13', 109998.00, 'Credit Card', 'Success'),
(11, '2025-08-20', 4999.00, 'UPI', 'Refunded'),
(12, '2025-08-27', 799.00, 'UPI', 'Success'),
(13, '2025-09-02', 499.00, 'UPI', 'Success'),
(14, '2025-09-06', 4496.00, 'UPI', 'Success'),
(15, '2025-09-12', 8996.00, 'UPI', 'Success'),
(16, '2025-09-19', 399.00, 'UPI', 'Success'),
(17, '2025-09-25', 13456.00, 'UPI', 'Success'),
(18, '2025-10-02', 250.00, 'UPI', 'Failed'),
(19, '2025-10-07', 2348.00, 'UPI', 'Success'),
(20, '2025-10-12', 79998.00, 'Net Banking', 'Success'),
(21, '2025-10-19', 3197.00, 'UPI', 'Success'),
(22, '2025-10-26', 1598.00, 'UPI', 'Success'),
(23, '2025-10-31', 9997.00, 'Debit Card', 'Success'),
(24, '2025-11-07', 56197.00, 'Net Banking', 'Success'),
(25, '2025-11-11', 399.00, 'UPI', 'Refunded'),
(26, '2025-11-18', 877.00, 'UPI', 'Success'),
(27, '2025-11-24', 1648.00, 'UPI', 'Success'),
(28, '2025-11-29', 899.00, 'UPI', 'Success'),
(29, '2025-12-05', 738.00, 'UPI', 'Success'),
(30, '2025-12-11', 2197.00, 'UPI', 'Pending'),
(31, '2025-12-18', 2997.00, 'Debit Card', 'Success'),
(32, '2025-12-24', 899.00, 'UPI', 'Success'),
(33, '2025-12-29', 3999.00, 'Debit Card', 'Refunded'),
(34, '2026-01-05', 2499.00, 'UPI', 'Success'),
(35, '2026-01-10', 51998.00, 'Net Banking', 'Success'),
(36, '2026-01-17', 1799.00, 'UPI', 'Success'),
(37, '2026-01-23', 48998.00, 'Credit Card', 'Success'),
(38, '2026-01-28', 5296.00, 'UPI', 'Success'),
(39, '2026-02-03', 4158.00, 'UPI', 'Success'),
(40, '2026-02-10', 39999.00, 'Net Banking', 'Success'),
(41, '2026-02-15', 18999.00, 'UPI', 'Failed'),
(42, '2026-02-23', 599.00, 'UPI', 'Success'),
(43, '2026-02-27', 2598.00, 'UPI', 'Success'),
(44, '2026-03-06', 1299.00, 'UPI', 'Success'),
(45, '2026-03-12', 18999.00, 'Net Banking', 'Success'),
(46, '2026-03-17', 4796.00, 'UPI', 'Pending'),
(47, '2026-03-25', 7695.00, 'Debit Card', 'Success'),
(48, '2026-03-29', 18996.00, 'UPI', 'Success'),
(49, '2026-04-04', 1799.00, 'UPI', 'Refunded'),
(50, '2026-04-10', 7797.00, 'UPI', 'Success'),
(51, '2026-04-16', 49298.00, 'Net Banking', 'Success'),
(52, '2026-04-23', 12997.00, 'Credit Card', 'Success'),
(53, '2026-04-30', 2999.00, 'UPI', 'Success'),
(54, '2026-05-05', 22996.00, 'Net Banking', 'Success'),
(55, '2026-05-10', 7999.00, 'Credit Card', 'Success'),
(56, '2026-05-16', 25496.00, 'UPI', 'Success'),
(57, '2026-05-22', 1499.00, 'Debit Card', 'Failed'),
(58, '2026-05-29', 6998.00, 'Net Banking', 'Success'),
(59, '2026-06-03', 3498.00, 'Debit Card', 'Success'),
(60, '2026-06-10', 449.00, 'Debit Card', 'Success');

SELECT COUNT(PaymentID) FROM Payments;
SELECT * FROM Payments;

INSERT INTO Shipments(OrderID, ShipDate, DeliveryDate, ShipmentStatus, Courier)
VALUES
(1, '2025-06-21', '2025-06-26', 'Delivered', 'India Post'),
(2, '2025-06-29', '2025-07-04', 'Delivered', 'DTDC'),
(4, '2025-07-09', '2025-07-15', 'Delivered', 'India Post'),
(5, '2025-07-15', '2025-07-21', 'Delivered', 'Ekart'),
(6, '2025-07-21', NULL, 'In Transit', 'BlueDart'),
(7, '2025-07-27', '2025-08-02', 'Delivered', 'DTDC'),
(9, '2025-08-09', '2025-08-12', 'Delivered', 'BlueDart'),
(10, '2025-08-14', '2025-08-16', 'Delivered', 'Delhivery'),
(12, '2025-08-27', '2025-09-01', 'Delivered', 'XpressBees'),
(13, '2025-09-03', NULL, 'In Transit', 'India Post'),
(14, '2025-09-07', '2025-09-13', 'Delivered', 'DTDC'),
(16, '2025-09-20', '2025-09-22', 'Delivered', 'XpressBees'),
(17, '2025-09-27', '2025-09-29', 'Delivered', 'DTDC'),
(19, '2025-10-07', '2025-10-09', 'Delivered', 'XpressBees'),
(20, '2025-10-13', NULL, 'In Transit', 'BlueDart'),
(21, '2025-10-20', '2025-10-26', 'Delivered', 'Delhivery'),
(22, '2025-10-27', '2025-11-01', 'Delivered', 'DTDC'),
(24, '2025-11-07', '2025-11-10', 'Delivered', 'Delhivery'),
(26, '2025-11-20', '2025-11-25', 'Delivered', 'BlueDart'),
(27, '2025-11-24', NULL, 'In Transit', 'BlueDart'),
(28, '2025-11-30', '2025-12-06', 'Delivered', 'Delhivery'),
(29, '2025-12-08', '2025-12-10', 'Delivered', 'BlueDart'),
(31, '2025-12-20', '2025-12-26', 'Delivered', 'India Post'),
(32, '2025-12-25', '2025-12-29', 'Delivered', 'Delhivery'),
(34, '2026-01-05', '2026-01-10', 'Delivered', 'Ekart'),
(35, '2026-01-12', NULL, 'In Transit', 'DTDC'),
(36, '2026-01-18', '2026-01-23', 'Delivered', 'Ekart'),
(37, '2026-01-24', '2026-01-29', 'Delivered', 'India Post'),
(39, '2026-02-05', '2026-02-07', 'Delivered', 'BlueDart'),
(40, '2026-02-10', '2026-02-15', 'Delivered', 'XpressBees'),
(42, '2026-02-22', '2026-02-24', 'Delivered', 'India Post'),
(43, '2026-03-02', NULL, 'In Transit', 'Ekart'),
(44, '2026-03-08', '2026-03-11', 'Delivered', 'Ekart'),
(45, '2026-03-14', '2026-03-18', 'Delivered', 'Ekart'),
(47, '2026-03-26', '2026-03-28', 'Delivered', 'Ekart'),
(48, '2026-03-30', '2026-04-02', 'Delivered', 'XpressBees'),
(50, '2026-04-13', '2026-04-17', 'Delivered', 'DTDC'),
(51, '2026-04-18', NULL, 'In Transit', 'Ekart'),
(52, '2026-04-24', '2026-04-26', 'Delivered', 'Delhivery'),
(53, '2026-04-29', '2026-05-02', 'Delivered', 'BlueDart'),
(55, '2026-05-12', '2026-05-15', 'Delivered', 'DTDC'),
(56, '2026-05-19', '2026-05-25', 'Delivered', 'BlueDart'),
(58, '2026-05-31', '2026-06-05', 'Delivered', 'Delhivery'),
(59, '2026-06-04', NULL, 'In Transit', 'XpressBees'),
(60, '2026-06-12', '2026-06-14', 'Delivered', 'BlueDart');

SELECT COUNT(ShipmentID) FROM Shipments;
SELECT * FROM Shipments;

INSERT INTO Reviews(CustomerID, ProductID, Rating, Comment, ReviewDate)
VALUES
(3, 61, 3, 'Okay for the price, nothing special.', '2025-07-15'),
(7, 5, 1, 'Did not match the description.', '2025-07-21'),
(3, 4, 5, 'Works perfectly, very satisfied.', '2025-08-02'),
(3, 38, 2, 'Poor packaging, item was damaged.', '2025-07-26'),
(19, 6, 4, 'Fast delivery and good packaging.', '2025-07-31'),
(8, 4, 5, 'Works perfectly, very satisfied.', '2025-08-11'),
(7, 37, 4, 'Fast delivery and good packaging.', '2025-08-27'),
(45, 3, 4, 'Works perfectly, very satisfied.', '2025-08-23'),
(50, 19, 4, 'Works perfectly, very satisfied.', '2025-09-16'),
(33, 20, 2, 'Did not match the description.', '2025-09-19'),
(33, 53, 5, 'Excellent product, highly recommend!', '2025-09-19'),
(41, 37, 5, 'Exceeded my expectations.', '2025-10-06'),
(5, 14, 2, 'Poor packaging, item was damaged.', '2025-10-18'),
(3, 30, 3, 'Okay for the price, nothing special.', '2025-10-31'),
(3, 24, 5, 'Exceeded my expectations.', '2025-10-28'),
(14, 32, 3, 'Average quality, expected a bit more.', '2025-10-28'),
(14, 34, 1, 'Poor packaging, item was damaged.', '2025-11-07'),
(60, 39, 3, 'Packaging could be better.', '2025-11-04'),
(22, 43, 4, 'Exceeded my expectations.', '2025-11-28'),
(45, 45, 2, 'Poor packaging, item was damaged.', '2025-12-09'),
(18, 61, 3, 'Okay for the price, nothing special.', '2025-12-19'),
(50, 45, 1, 'Did not match the description.', '2025-12-24'),
(12, 25, 2, 'Poor packaging, item was damaged.', '2026-01-06'),
(38, 61, 3, 'Decent product, does the job.', '2026-01-02'),
(3, 40, 4, 'Exactly as described, happy with purchase.', '2026-01-22'),
(15, 26, 4, 'Good quality for the price.', '2026-02-01'),
(7, 6, 5, 'Fast delivery and good packaging.', '2026-02-01'),
(58, 44, 2, 'Product stopped working after a few days.', '2026-02-26'),
(58, 23, 5, 'Excellent product, highly recommend!', '2026-02-17'),
(40, 6, 5, 'Excellent product, highly recommend!', '2026-02-25'),
(11, 43, 3, 'Okay for the price, nothing special.', '2026-03-14'),
(33, 17, 3, 'Packaging could be better.', '2026-03-24'),
(24, 10, 3, 'Decent product, does the job.', '2026-03-21'),
(6, 40, 5, 'Good quality for the price.', '2026-04-12'),
(6, 42, 5, 'Exceeded my expectations.', '2026-04-17'),
(48, 56, 2, 'Product stopped working after a few days.', '2026-04-12'),
(48, 58, 5, 'Good quality for the price.', '2026-04-21'),
(21, 26, 3, 'Packaging could be better.', '2026-05-04'),
(12, 11, 5, 'Excellent product, highly recommend!', '2026-05-04'),
(45, 7, 5, 'Works perfectly, very satisfied.', '2026-05-16'),
(7, 56, 5, 'Exactly as described, happy with purchase.', '2026-05-20'),
(30, 10, 4, 'Fast delivery and good packaging.', '2026-06-03'),
(30, 41, 5, 'Excellent product, highly recommend!', '2026-06-04'),
(3, 55, 1, 'Did not match the description.', '2026-06-09'),
(17, 48, 3, 'Average quality, expected a bit more.', '2026-06-17'),
(48, 10, 4, 'Good quality for the price.', '2026-06-18');

SELECT COUNT(ReviewID) FROM Reviews;
SELECT * FROM Reviews;

INSERT INTO Return_Requests(OrderID, ReturnReason, ReturnDate, ReturnStatus)
VALUES
(2, 'Item not working properly', '2025-07-06', 'Approved'),
(4, 'Received wrong product', '2025-07-22', 'Approved'),
(31, 'Item not working properly', '2026-01-02', 'Rejected'),
(56, 'Received wrong product', '2026-05-27', 'Processing'),
(21, 'Quality not as expected', '2025-11-01', 'Processing'),
(10, 'Ordered by mistake', '2025-08-22', 'Rejected'),
(45, 'Ordered by mistake', '2026-03-25', 'Approved');

SELECT COUNT(ReturnID) FROM Return_Requests;
SELECT * FROM Return_Requests;


-- Data Analysis

-- Select all products where price is greater than 5000

SELECT * FROM Products
WHERE Price > 5000;

-- Select all products sorted by price from highest to lowest

SELECT * FROM Products
ORDER BY Price DESC;

-- Display product name and price for a particular category
-- Sort the result by price from lowest to highest

SELECT 
	ProductName,
    Price
FROM Products
WHERE CategoryID = 6
ORDER BY Price ASC;

-- Display customer name and email for customers in Chennai
-- Sort the result by name in alphabetical order

SELECT
	CustomerName,
    Email
FROM Customers
WHERE Address = 'Chennai'
ORDER BY CustomerName ASC;

-- Display product name, category and price for products priced between 1000 and 5000
-- Product name should contain 'set' and results sorted in descending order

SELECT 
	ProductName,
    CategoryID,
    Price
FROM Products
WHERE 
	Price BETWEEN 1000 AND 5000
    AND ProductName LIKE '%set%'
ORDER BY Price DESC;

-- Display the total number of orders that are delivered

SELECT 
	COUNT(OrderID) AS number_delivered,
	OrderStatus
FROM Orders
WHERE OrderStatus = 'Delivered';

-- Display the average total revenue across all orders

SELECT AVG(TotalAmount) AS average_total_revenue
FROM Orders;

-- Display total revenue from successful payments only

SELECT SUM(Amount) AS total_revenue
FROM Payments
WHERE PaymentStatus = 'Success';

-- Display the highest and lowest price amongst all products

SELECT 
	MAX(Price) AS highest_price,
    MIN(Price) AS lowest_price
FROM Products;

-- Display the total number of reviews and average rating for ratings of 3 or above

SELECT
	COUNT(ReviewID) AS total_reviews,
    AVG(Rating) AS average_rating
FROM Reviews
WHERE Rating >= 3;

-- Display the total quantity sold for items priced above 2000

SELECT
	SUM(Quantity) AS total_quantity_sold
FROM Order_Items
WHERE Price > 2000;

-- Display the number of products in each category

SELECT 
	COUNT(ProductID),
    CategoryID
FROM Products
GROUP BY CategoryID;

-- Display the total stock available for each product

SELECT
	SUM(StockQuantity),
    ProductID
FROM Inventory
GROUP BY ProductID;

-- Display the total amount spent by each customer

SELECT
	SUM(TotalAmount),
    CustomerID
FROM Orders
GROUP BY CustomerID;

-- Display the number of orders for each order status

SELECT 
	Count(OrderID),
    OrderStatus
FROM Orders
GROUP BY OrderStatus;

-- Display the average product price for each category

SELECT
	AVG(Price) AS average_price,
    CategoryID 
FROM Products
GROUP BY CategoryID;

-- Display the total payment amount for each payment method for successful payments

SELECT
	PaymentMethod,
    SUM(Amount)
FROM Payments
WHERE PaymentStatus = 'Success'
GROUP BY PaymentMethod;

-- Display categories that contain more than 3 products

SELECT 
	COUNT(ProductID),
    CategoryID
FROM Products
GROUP BY CategoryID
HAVING COUNT(ProductID) > 3;

-- Display customers whose total spending is greater than 20,000

SELECT 
	CustomerID,
    SUM(TotalAmount) AS total_spending
FROM Orders
GROUP BY CustomerID 
HAVING SUM(TotalAmount) > 20000;

-- Display payment methods whose total successful payment exceeds 50,000

SELECT
	PaymentMethod,
    SUM(Amount) AS total_successful_payment
FROM Payments
GROUP BY PaymentMethod
HAVING SUM(Amount) > 50000;

-- Display product categories whose average product price is greater than 5,000

SELECT
	CategoryID,
    AVG(Price) AS average_price
FROM Products
GROUP BY CategoryID
HAVING average_price > 5000;

-- Display customer name and order details by joining Customers and Orders tables

SELECT 
	cu.CustomerName,
    o.OrderID,
    o.OrderDate,
    o.TotalAmount
FROM Orders AS o
INNER JOIN Customers AS cu
ON o.CustomerID = cu.CustomerID;

-- Display product and category name by joining Products and Categories tables

SELECT 
	p.ProductName,
    c.CategoryName
FROM Products AS p
INNER JOIN Categories AS c
ON p.CategoryID = c.CategoryID;

-- Display product name, seller name and product price by joining Products and Sellers tables

SELECT 
	p.ProductName,
    s.SellerName,
    p.Price
FROM Products AS p
INNER JOIN Sellers AS s
ON p.SellerID = s.SellerID;

-- Display order ID, payment method, payment status and payment amount by joining Orders and Payments tables

SELECT 
	o.OrderID, 
    pa.PaymentMethod,
    pa.PaymentStatus,
    pa.Amount
FROM Payments AS pa
INNER JOIN Orders AS o
ON pa.OrderID = o.OrderID;

-- Display customer name, order ID, payment method, payment status and payment amount by joining Customers, Orders and Payments tables

SELECT 
	cu.CustomerName,
    o.OrderID,
    p.PaymentMethod,
    p.PaymentStatus,
    p.Amount
FROM Payments AS p
INNER JOIN Orders AS o
ON p.OrderID = o.OrderID
INNER JOIN Customers AS cu
ON o.CustomerID = cu.CustomerID;

-- Display product name, category name, seller name and product price by joining Products, Categories and Sellers tables

SELECT 
	p.ProductName,
    c.CategoryName,
    s.SellerName,
    p.Price
FROM Products AS p
INNER JOIN Categories AS c
ON p.CategoryID = c.CategoryID
INNER JOIN Sellers AS s
ON p.SellerID = s.SellerID;

-- Display customer name, order ID, product name, quantity and price by joining Customers, Orders, Order_Items and Products tables

SELECT 
	cu.CustomerName,
    o.OrderID,
    p.ProductName,
    oi.Quantity,
    p.Price
FROM Order_Items AS oi
INNER JOIN Orders AS o
ON o.OrderID = oi.OrderID
INNER JOIN Customers AS cu
ON o.CustomerID = cu.CustomerID
INNER JOIN Products AS p
ON oi.ProductID = p.ProductID;

-- Display customer name, order ID, payment method, shipment status, and total order amount by joining Customers, Orders, Payments and Shipments tables

SELECT 
	cu.CustomerName,
    o.OrderID,
    pa.PaymentMethod,
    sh.ShipmentStatus,
    o.TotalAmount
FROM Orders AS o
LEFT JOIN Payments AS pa
ON o.OrderID = pa.OrderID
LEFT JOIN Shipments AS sh
ON o.OrderID = sh.OrderID
LEFT JOIN Customers AS cu
ON o.CustomerID = cu.CustomerID;

-- Display all customers and their orders, including customers who have never placed an order

SELECT 
	cu.CustomerName,
    o.OrderID
FROM Customers AS cu
LEFT JOIN Orders AS o
ON o.CustomerID = cu.CustomerID;

-- Display all products and their reviews, including products that have not received reviews

SELECT 
	p.ProductName,
    r.Rating
FROM Products AS p
LEFT JOIN Reviews AS r
ON p.ProductID = r.ProductID;

-- Display all sellers and their products, including sellers who have not listed any products

SELECT 
	s.SellerName,
    p.ProductName
FROM Sellers AS s
LEFT JOIN Products AS p
ON p.SellerID = s.SellerID;

-- Display all orders and their shipment details, including orders that have not been shipped

SELECT 
	o.OrderID,
    o.OrderDate,
    sh.ShipmentStatus
FROM Orders AS o
LEFT JOIN Shipments AS sh
ON o.OrderID = sh.OrderID;

-- Display products whose price is greater than the average price of all products

SELECT
	ProductName,
    Price
FROM Products
WHERE Price > (SELECT AVG(Price) FROM Products)
ORDER BY Price ASC;

-- Display customers whose total spending is greater than the average order amount

SELECT
	CustomerID,
    SUM(TotalAmount) AS total_spending
FROM Orders
GROUP BY CustomerID
HAVING SUM(TotalAmount) > (SELECT AVG(TotalAmount) FROM Orders);

-- Display products whose price is equal to the highest product price

SELECT
	ProductID,
    ProductName,
    Price
FROM Products
WHERE Price = (SELECT MAX(Price) FROM Products);

-- Display orders whose total amount is greater than the average total amount of all orders

SELECT 
	OrderID,
    TotalAmount
FROM Orders 
WHERE TotalAmount > (SELECT AVG(TotalAmount) FROM Orders);

-- Display products with a row number based on price in descending order

SELECT
	ProductName,
    Price,
    ROW_NUMBER() OVER(ORDER BY Price DESC) AS price_row_number
FROM Products;

-- Display products with their rank based on price in descending order

SELECT
	ProductName,
    Price,
    RANK() OVER(ORDER BY Price DESC) AS price_rank
FROM Products;

-- Display products with their dense rank based on price in descending order

SELECT
	ProductName,
    Price,
    DENSE_RANK() OVER(ORDER BY Price DESC) AS price_dense_rank 
FROM Products;

-- Display products with a row number within each category based on price in descending order

SELECT
	ProductName,
    CategoryID,
    Price,
    ROW_NUMBER() OVER(PARTITION BY CategoryID ORDER BY Price DESC) AS price_row_number
FROM Products;

-- Display products with their rank within each category based on price in descending order

SELECT 
	ProductName,
    CategoryID,
    Price,
    RANK() OVER(PARTITION BY CategoryID ORDER BY Price DESC) AS price_rank
FROM Products;

-- Display products with their dense rank within each category based on price in descending order

SELECT 
	ProductName,
    CategoryID,
    Price,
    DENSE_RANK() OVER(PARTITION BY CategoryID ORDER BY Price DESC) AS price_dense_rank
FROM Products;


-- View Implementation

-- Create a view to display customer names and their order details

CREATE VIEW VW_CustomerOrders
AS
	(SELECT
		cu.CustomerName,
		o.OrderID,
		o.OrderDate,
		o.TotalAmount
	FROM Orders AS o
	INNER JOIN Customers AS cu
	ON o.CustomerID = cu.CustomerID);

SELECT * FROM VW_CustomerOrders;

-- Create a view to display product name, category name, seller name and price

CREATE VIEW VW_ProductDetails
AS
	(SELECT
		p.ProductName,
		c.CategoryName,
		s.SellerName,
		p.Price
	FROM Products AS p
	INNER JOIN Categories AS c
	ON p.CategoryID = c.CategoryID
	INNER JOIN Sellers AS s
	ON p.SellerID = s.SellerID);

SELECT * FROM VW_ProductDetails;

-- Create a view to display customer name, order ID, payment method, payment status and order amount

CREATE VIEW VW_PaymentDetails
AS
	(SELECT
		cu.CustomerName,
		o.OrderID,
		pa.PaymentMethod,
		pa.PaymentStatus,
		o.TotalAmount
	FROM Payments AS pa
	INNER JOIN Orders AS o
	ON pa.OrderID = o.OrderID
	INNER JOIN Customers AS cu
	ON o.CustomerID = cu.CustomerID);

SELECT * FROM VW_PaymentDetails;


-- Stored Procedure Implementation

-- Create a stored procedure to display all orders of a given customer

DROP PROCEDURE IF EXISTS P_GetCustomerOrders;

DELIMITER $$
CREATE PROCEDURE P_GetCustomerOrders(IN cusID INT)
BEGIN
	SELECT 
		OrderID, 
        OrderDate,
        TotalAmount,
        CustomerID
	FROM Orders
    WHERE CustomerID = cusID;
END $$
DELIMITER ;

CALL P_GetCustomerOrders(3);

-- Create a stored procedure to display all products belonging to a specific category

DROP PROCEDURE IF EXISTS P_GetProductsByCategory;

DELIMITER $$
CREATE PROCEDURE P_GetProductsByCategory(IN catID INT)
BEGIN
	SELECT 
		ProductID,
        ProductName,
        Price,
        CategoryID
	FROM Products
    WHERE CategoryID = catID;
END $$
DELIMITER ; 

CALL P_GetProductsByCategory(1)


-- Trigger Implementation

-- Create a trigger that reduces product stock when a new order is inserted

DROP TRIGGER IF EXISTS T_ReduceStock;

DELIMITER $$
CREATE TRIGGER T_ReduceStock
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
	UPDATE Inventory
		SET StockQuantity = StockQuantity - NEW.Quantity 
        WHERE ProductID = NEW.ProductID;
END $$
DELIMITER ;

INSERT INTO Order_Items(OrderID, ProductID, Quantity, Price)
VALUES
(2, 5, 3, 2500);

SELECT * FROM Inventory
WHERE ProductID = 5;

-- Create a trigger that prevents inserting payments with a negative amount

DROP TRIGGER IF EXISTS T_CheckPaymentAmount;

DELIMITER $$
CREATE TRIGGER T_CheckPaymentAmount
BEFORE INSERT ON Payments
FOR EACH ROW
BEGIN
	IF NEW.Amount < 0 THEN SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Payment amount cannot be negative';
	END IF; 
END $$
DELIMITER ; 

INSERT INTO Payments(OrderID, PaymentDate, Amount, PaymentMethod, PaymentStatus)
VALUES
(1, CURDATE(), 5000, 'UPI', 'Success');

INSERT INTO Payments(OrderID, PaymentDate, Amount, PaymentMethod, PaymentStatus)
VALUES
(2, CURDATE(), -450, 'UPI', 'Success');

-- Create triggers that manage the entire inventory

DROP TRIGGER IF EXISTS T_CheckReduceStock;
DROP TRIGGER IF EXISTS T_AdjustStockAfterUpdate;
DROP TRIGGER IF EXISTS T_RestoreStockAfterDelete;

DELIMITER $$

CREATE TRIGGER T_CheckReduceStock
BEFORE INSERT ON Order_Items
FOR EACH ROW
BEGIN

	DECLARE 
		AvailableStock INT;
    
    SELECT 
		StockQuantity
    INTO 
		AvailableStock
    FROM Inventory
    WHERE ProductID = NEW.ProductID;
    
    IF AvailableStock IS NULL THEN
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Product does not exist in inventory';
	END IF;
    
    IF AvailableStock < NEW.Quantity THEN
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient stock available';
	END IF;
    
    UPDATE Inventory
		SET StockQuantity = StockQuantity - NEW.Quantity
        WHERE ProductID = NEW.ProductID;

END $$

CREATE TRIGGER T_AdjustStockAfterUpdate
AFTER UPDATE ON Order_Items
FOR EACH ROW
BEGIN

	DECLARE 
		QuantityDifference INT;
        
	SET QuantityDifference = NEW.Quantity - OLD.Quantity;
	
    UPDATE Inventory
		SET StockQuantity = StockQuantity - QuantityDifference
        WHERE ProductID = NEW.ProductID;

END $$

CREATE TRIGGER T_RestoreStockAfterDelete
AFTER DELETE ON Order_Items
FOR EACH ROW
BEGIN
	
    UPDATE Inventory
		SET StockQuantity = StockQuantity + OLD.Quantity
        WHERE ProductID = OLD.ProductID;

END $$

DELIMITER ; 

