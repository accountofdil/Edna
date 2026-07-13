-- Database Creation

CREATE DATABASE apple_data_analysis;

DROP TABLE IF EXISTS warranties;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS products; 
DROP TABLE IF EXISTS categories; 
DROP TABLE IF EXISTS stores;

CREATE TABLE stores(
				store_id VARCHAR(5) PRIMARY KEY,
				store_name VARCHAR(30),
				city VARCHAR(25),
				country VARCHAR(25));

CREATE TABLE categories(
					category_id VARCHAR(10) PRIMARY KEY,
					category_name VARCHAR(20));

CREATE TABLE products(	
					product_id VARCHAR(10) PRIMARY KEY,
					product_name VARCHAR(35),
					category_id VARCHAR(10),
					launch_date DATE, 
					price FLOAT,
					CONSTRAINT fk_category FOREIGN KEY (category_id) REFERENCES categories(category_id));

CREATE TABLE sales(
				sale_id VARCHAR(15) PRIMARY KEY,
				sale_date DATE,
				store_id VARCHAR(10), 
				product_id VARCHAR(10),
				quantity INT, 
				CONSTRAINT fk_store FOREIGN KEY (store_id) REFERENCES stores(store_id),
				CONSTRAINT fk_product FOREIGN KEY (product_id) REFERENCES products(product_id));

CREATE TABLE warranties(
					claim_id VARCHAR(10) PRIMARY KEY, 
					claim_date DATE, 
					sale_id VARCHAR(15),
					repair_status VARCHAR(15),
					CONSTRAINT fk_orders FOREIGN KEY (sale_id) REFERENCES sales(sale_id));

SELECT * FROM stores;
SELECT * FROM categories; 
SELECT * FROM products;
SELECT * FROM sales;
SELECT * FROM warranties;

SELECT DISTINCT repair_status FROM warranties;
SELECT COUNT(*) FROM sales;

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 'P-44';

CREATE INDEX sales_product_id ON sales(product_id);

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE product_id = 'P-44';

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-31';

CREATE INDEX sales_store_id ON sales(store_id);

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id = 'ST-31';

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE sale_date = '2022-03-28';

CREATE INDEX sales_sale_date ON sales(sale_date);

EXPLAIN ANALYZE
SELECT * FROM sales
WHERE sale_date = '2022-03-28';


-- Data Analysis

-- Find the number of stores in each country

SELECT 
	country,
	COUNT(store_id) AS total_stores
FROM stores
GROUP BY 1
ORDER BY 2 DESC;

-- Calculate the total number of units sold by each store

SELECT
	s.store_id,
	st.store_name,
	SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Identify the number of sales that occurred in December 2023

SELECT 
	COUNT(sale_id) AS total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '12-2023';

-- Determine the number of stores that have never had a warranty claim filed

SELECT 
	COUNT(*)
FROM stores
WHERE store_id NOT IN
					(SELECT 
						DISTINCT s.store_id
					FROM sales AS s
					RIGHT JOIN warranties AS w
					ON s.sale_id = w.sale_id);

-- Calculate the percentage of warranty claims marked as 'Warranty Void'

SELECT 	
	ROUND(COUNT(claim_id) / 
			(SELECT COUNT(*) FROM warranties)::numeric * 100, 2) AS w_void_percentage
FROM warranties
WHERE repair_status = 'Warranty Void';

-- Identify which store had the highest total units sold in the past 3 years

SELECT 
	s.store_id,
	st.store_name,
	SUM(s.quantity)
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
WHERE sale_date >= (CURRENT_DATE - INTERVAL '3 year')
GROUP BY 1, 2
ORDER BY 2 DESC
LIMIT 1;

-- Count the number of unique products sold in the past 3 years

SELECT 
	COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (CURRENT_DATE - INTERVAL '3 year');

-- Find the average price of products in each category

SELECT 
	p.category_id,
	c.category_name,
	AVG(p.price) AS average_price
FROM products AS p
JOIN categories AS c
ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Find the number of warranty claims that were filed in 2020

SELECT 
	COUNT(*) AS total_claims
FROM warranties
WHERE EXTRACT(YEAR FROM claim_date) = 2020;

-- For each store, identify the best-selling day based on the highest quantity sold

SELECT *
FROM
	(SELECT 
		s.store_id,
		st.store_name,
		TO_CHAR(s.sale_date, 'Day') AS day_name,
		SUM(s.quantity) AS total_units_sold,
		RANK() OVER(PARTITION BY s.store_id ORDER BY SUM(s.quantity) DESC) AS rank
	FROM sales AS s
	JOIN stores AS st
	ON st.store_id = s.store_id
	GROUP BY 1, 2, 3) AS t1
WHERE rank = 1;

-- Identify the least selling product in each country and for each year based on total units sold

WITH product_rank
AS
	(SELECT 
		st.country,
		p.product_name,
		SUM(s.quantity) AS total_sales,
		RANK () OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) AS rank
	FROM sales AS s
	JOIN stores AS st
	ON s.store_id = st.store_id
	JOIN products AS p
	ON s.product_id = p.product_id
	GROUP BY 1, 2)
SELECT * FROM product_rank
WHERE rank = 1;

-- Calculate the number of warranty claims that were filed within 180 days of a product sale

SELECT 
	w.*,
	s.sale_date,
	w.claim_date - s.sale_date AS elapsed_time_claim
FROM warranties AS w
LEFT JOIN sales AS s
ON s.sale_id = w.sale_id
WHERE 
	w.claim_date - s.sale_date <= 180;

SELECT 
	COUNT(*)
FROM warranties AS w
LEFT JOIN sales AS s
ON s.sale_id = w.sale_id
WHERE 
	w.claim_date - s.sale_date <= 180;

-- Determine the number of warranty claims that were filed for products launched in the past 4 years

SELECT
	p.product_name,
	COUNT(w.claim_id) AS number_of_claims
FROM warranties AS w
JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '4 year'
GROUP BY 1;

SELECT
	p.product_name,
	COUNT(w.claim_id) AS number_of_claims,
	COUNT(s.sale_id) AS total_sales
FROM warranties AS w
RIGHT JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE p.launch_date >= CURRENT_DATE - INTERVAL '4 year'
GROUP BY 1
HAVING COUNT(w.claim_id) > 0;

-- List the months in the last 4 years where sales exceeded 5,000 units in the USA

SELECT 
	TO_CHAR(sale_date, 'MM-YYYY') AS month,
	SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
WHERE 
	st.country = 'USA'
	AND 
	s.sale_date >= CURRENT_DATE - INTERVAL '4 year'
GROUP BY 1
HAVING SUM(s.quantity) > 5000;

-- Identify the product category with the most warranty claims filed in the last 3 years

SELECT 
	c.category_name,
	COUNT(w.claim_id) AS total_claims
FROM warranties AS w
LEFT JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
JOIN categories AS c
ON c.category_id = p.category_id
WHERE 
	w.claim_date >= CURRENT_DATE - INTERVAL '3 year'
GROUP BY 1
ORDER BY 2 DESC;

-- For each country, determine percentage chance of receiving warranty claims after each purchase

SELECT 
	country,
	total_units_sold,
	total_claims,
	COALESCE(total_claims::numeric / total_units_sold::numeric * 100, 0) AS risk_chance
FROM
	(SELECT 
		st.country,
		SUM(s.quantity) AS total_units_sold,
		COUNT(w.claim_id) AS total_claims
	FROM sales AS s
	JOIN stores AS st
	ON s.store_id = st.store_id
	LEFT JOIN warranties AS w
	ON w.sale_id = s.sale_id
	GROUP BY 1) AS t1
ORDER BY 4 DESC;

-- Analyse the year-by-year growth ratio for each store

WITH yearly_sales
AS
	(SELECT 
		s.store_id, 
		st.store_name,
		EXTRACT(YEAR FROM sale_date) AS year,
		SUM (s.quantity * p.price) AS total_sales
	FROM sales AS s
	JOIN products AS p
	ON s.product_id = p.product_id
	JOIN stores AS st
	ON st.store_id = s.store_id
	GROUP BY 1, 2, 3
	ORDER BY 2, 3),
growth_ratio
AS
	(SELECT
		store_name,
		year,
		LAG(total_sales, 1) OVER(PARTITION BY store_name ORDER BY year) AS last_year_sales,
		total_sales AS current_year_sales
	FROM yearly_sales)
SELECT
	store_name,
	year,
	last_year_sales,
	current_year_sales,
	ROUND((current_year_sales - last_year_sales)::numeric / last_year_sales::numeric * 100, 3) AS growth_ratio
FROM growth_ratio
WHERE 
	last_year_sales IS NOT NULL
	AND 
	YEAR <> EXTRACT(YEAR FROM CURRENT_DATE);
	
-- Calculate the correlation between product price and warranty claims 
-- Ensure the calculation is for products sold in the past 5 years and is segmented by price range

SELECT 
	CASE
		WHEN p.price < 500 THEN 'Less Expensive Product'
		WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid-Range Product'
		ELSE 'Expensive Product'
	END AS price_segment,
	COUNT(w.claim_id) AS total_claims
FROM warranties AS w
LEFT JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '5 year'
GROUP BY 1;

-- Identify the store with highest percentage of 'Paid Repaired' claims relative to total claims filed

WITH paid_repaired
AS
	(SELECT 
		s.store_id, 
		COUNT(w.claim_id) AS paid_repaired
	FROM sales AS s
	RIGHT JOIN warranties AS w
	ON s.sale_id = w.sale_id
	WHERE w.repair_status = 'Paid Repaired'
	GROUP BY 1),
total_repaired
AS
	(SELECT 
		s.store_id, 
		COUNT(w.claim_id) AS total_repaired
	FROM sales AS s
	RIGHT JOIN warranties AS w
	ON s.sale_id = w.sale_id
	GROUP BY 1)
SELECT
	tr.store_id, 
	st.store_name,
	pr.paid_repaired,
	tr.total_repaired,
	ROUND(pr.paid_repaired::numeric / tr.total_repaired::numeric * 100, 2) AS percentage_paid_repaired
FROM paid_repaired AS pr
JOIN total_repaired AS tr
ON pr.store_id = tr.store_id
JOIN stores AS st
ON tr.store_id = st.store_id

-- Calculate the monthly running total of sales for each store over the past 4 years 
-- Furthermore, compare sales trends during this period

WITH monthly_sales
AS
(SELECT 
	s.store_id,
	EXTRACT(YEAR FROM s.sale_date) AS year,
	EXTRACT(MONTH FROM s.sale_date) AS month,
	SUM(p.price * s.quantity) AS total_revenue
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3)
SELECT 
	store_id,
	month,
	year,
	total_revenue,
	SUM(total_revenue) OVER(PARTITION BY store_id ORDER BY year, month) AS running_total
FROM monthly_sales;

-- Analyse product sales trends over time, segmented into key periods
-- Ensure the periods are from launch to 6 months, 6-12 months, 12-18 months and beyond 18 months

SELECT 
	p.product_name,
	CASE 
		WHEN s.sale_date BETWEEN p.launch_date AND p.launch_date + INTERVAL '6 month' THEN '0-6 Month'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '6 month' AND p.launch_date + INTERVAL '12 month' THEN '6-12 Month'
		WHEN s.sale_date BETWEEN p.launch_date + INTERVAL '12 month' AND p.launch_date + INTERVAL '18 month' THEN '12-18 Month'
		ELSE '18+ Month'
	END AS product_lifecycle,
	SUM(s.quantity) AS total_sales
FROM sales AS s
JOIN products AS p
ON s.product_id = p.product_id
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
