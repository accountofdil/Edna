-- Database Creation

CREATE DATABASE monday_coffee_expansion_analysis;

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

CREATE TABLE city(
				city_id INT PRIMARY KEY,
				city_name VARCHAR(15),
				population BIGINT,
				estimated_rent FLOAT,
				city_rank INT);

SELECT * FROM city;

CREATE TABLE customers(
					customer_id INT PRIMARY KEY,
					customer_name VARCHAR(25),
					city_id INT,
					CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id));

SELECT * FROM customers;

CREATE TABLE products(
					product_id INT PRIMARY KEY,
					product_name VARCHAR(50),
					price FLOAT);

SELECT * FROM products;

CREATE TABLE sales(
				sale_id INT PRIMARY KEY,
				sale_date DATE,
				product_id INT,
				customer_id INT,
				total FLOAT,
				rating INT,
				CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
				CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id));

SELECT * FROM sales;


-- Data Analysis

-- Find number of people in each city estimated to consume coffee given 25% of the population does

SELECT
	city_name,
	ROUND((population * 0.25) / 1000000, 2) as coffee_consumers_in_millions,
	city_rank
FROM city
ORDER BY 2 DESC;

-- Find the total revenue generated from coffee sales across all cities in the last quarter of 2023

SELECT
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
WHERE 
	EXTRACT(YEAR FROM s.sale_date) = 2023
	AND
	EXTRACT(QUARTER FROM s.sale_date) = 4
GROUP BY 1
ORDER BY 2 DESC;
	
-- Find the number of units of each coffee product that have been sold

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Calculate the average sales amount per customer in each city

SELECT
	ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_customers,
	ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as average_sales_per_customer
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

-- Provide a list of cities along with their populations and estimated coffee consumers

WITH city_table_new AS 
	(SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city),
customers_table_new
AS
	(SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_customers
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1)
SELECT 
	customers_table_new.city_name,
	city_table_new.coffee_consumers as coffee_consumer_in_millions,
	customers_table_new.unique_customers
FROM city_table_new
JOIN 
customers_table_new
ON city_table_new.city_name = customers_table_new.city_name;

-- Find the top 3 selling products in each city based on sales volume

SELECT * FROM
	(SELECT 
		ci.city_name,
		p.product_name,
		COUNT(s.sale_id) as total_orders,
		DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as sales_rank
	FROM sales as s
	JOIN products as p
	ON s.product_id = p.product_id
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2) as t1
WHERE sales_rank <= 3;

-- Find the number of unique customers in each city who have purchased coffee products

SELECT * FROM products; 

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_customers
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;
	
-- Find each city and their average sale per customer plus average rent per customer

WITH city_table_new AS 
	(SELECT
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as average_sales_per_customer
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC),
city_rent_table AS 
	(SELECT 
		city_name,
		estimated_rent
	FROM city)
SELECT
	cr.city_name,
	cr.estimated_rent,
	ct.total_customers,
	ct.average_sales_per_customer,
	ROUND(cr.estimated_rent::numeric / ct.total_customers:: numeric, 2) as average_rent_per_customer
FROM city_rent_table as cr
JOIN city_table_new as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

-- Calculate the percentage growth (or decline) in sales over different time periods

WITH monthly_sales
AS
	(SELECT
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as year,
		SUM(s.total) as total_sales
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2),
growth_ratio
AS
	(SELECT 
		city_name,
		month,
		year,
		total_sales as current_month_sales,
		LAG(total_sales, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sales
	FROM monthly_sales)
SELECT 
	city_name,
	month,
	year,
	current_month_sales,
	last_month_sales,
	ROUND((current_month_sales - last_month_sales)::numeric / last_month_sales::numeric * 100, 2) as growth_ratio
FROM growth_ratio
WHERE last_month_sales IS NOT NULL;

-- Find the top 3 cities based on highest sales amount
-- Return city name, total sales, total rent, total customers and estimated number of coffee consumers

WITH city_table_new
AS
	(SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total)::numeric / COUNT(DISTINCT s.customer_id)::numeric, 2) as average_sales_per_customer
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY ci.city_name
	ORDER BY total_revenue DESC),
city_rent_table
AS 
	(SELECT 
		city_name,
		estimated_rent,
		ROUND((population * 0.25) / 1000000, 3) as estimated_coffee_consumers_in_millions
	FROM city)
SELECT 
	cr.city_name,
	ct.total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	cr.estimated_coffee_consumers_in_millions,
	ct.average_sales_per_customer,
	ROUND(cr.estimated_rent::numeric / ct.total_customers::numeric, 2) as average_rent_per_customer
FROM city_rent_table as cr
JOIN city_table_new as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;
