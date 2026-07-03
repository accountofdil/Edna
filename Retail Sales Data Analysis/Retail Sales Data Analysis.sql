-- Database Creation

CREATE DATABASE retail_sales_sql;

DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
			(
				transactions_id INT PRIMARY KEY,	
				sale_date DATE,
				sale_time TIME,	
				customer_id	INT,
				gender VARCHAR(15),
				age INT,
				category VARCHAR(15),	
				quantity INT,	
				price_per_unit FLOAT,	
				cogs FLOAT,	
				total_sale FLOAT
				);


-- Data Preprocessing 

SELECT * FROM retail_sales
LIMIT 10

SELECT 
	COUNT(*) 
FROM retail_sales

SELECT * FROM public.retail_sales
ORDER BY transactions_id ASC LIMIT 100

SELECT * FROM retail_sales
WHERE transactions_id IS NULL

SELECT * FROM retail_sales
WHERE sale_date IS NULL

SELECT * FROM retail_sales
WHERE sale_time IS NULL

SELECT * FROM retail_sales
	WHERE 
	transactions_id IS NULL
	OR
	sale_date IS NULL
	OR
	sale_time IS NULL
	OR
	customer_id IS NULL
	OR
	gender IS NULL
	OR
	age IS NULL
	OR
	category IS NULL
	OR
	quantity IS NULL
	OR
	price_per_unit IS NULL
	OR
	cogs IS NULL
	OR
	total_sale IS NULL;

DELETE FROM retail_sales
	WHERE 
	transactions_id IS NULL
	OR
	sale_date IS NULL
	OR
	sale_time IS NULL
	OR
	customer_id IS NULL
	OR
	gender IS NULL
	OR
	age IS NULL
	OR
	category IS NULL
	OR
	quantity IS NULL
	OR
	price_per_unit IS NULL
	OR
	cogs IS NULL
	OR
	total_sale IS NULL;

SELECT 
	COUNT(*) 
FROM retail_sales


-- Data Exploration

-- Number of Sales

SELECT COUNT(*) as total_sale FROM retail_sales

-- Number of Unique Customers

SELECT COUNT(DISTINCT customer_id) as total_sale FROM retail_sales

-- Number of Unique Categories

SELECT DISTINCT category FROM retail_sales


-- Data Analysis

-- Retrieval of all columns for sales made on 2022-11-05

SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';

-- Retrieval of all transactions where category is 'Clothing' and quantity sold is over 4 in Nov-2022

SELECT *
FROM retail_sales
WHERE category = 'Clothing'
	AND
	TO_CHAR(sale_date, 'YYYY-MM') = '2022-11'
	AND
	quantity >= 4

-- Calculation of total sales (total_sale) for each category

SELECT 
	category,
	SUM(total_sale) as net_sale,
	COUNT(*) as total_orders
FROM retail_sales
GROUP BY 1 

-- Retrieval of average age of customers who purchased items from 'Beauty' category

SELECT 
	ROUND(AVG(age), 2) as avg_age
FROM retail_sales 
WHERE category = 'Beauty'

-- Retrieval of all transactions where total_sale is greater than 1000

SELECT *
FROM retail_sales
WHERE total_sale > 1000

-- Retrieval of total number of transactions (transaction_id) made by each gender in each category

SELECT
	category,
	gender,
	COUNT(*) as total_transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY 1

-- Calculation of average sale for each month and retrieval of best selling month in each year

SELECT
	EXTRACT (YEAR FROM sale_date) as sale_year,
	EXTRACT (MONTH from sale_date) as sale_month,
	AVG(total_sale) as avg_sale
FROM retail_sales
GROUP BY sale_year, sale_month
ORDER BY 1, 3 DESC

SELECT * FROM 
(
	SELECT
		EXTRACT (YEAR FROM sale_date) as sale_year,
		EXTRACT (MONTH from sale_date) as sale_month,
		AVG(total_sale) as avg_sale,
		RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) as sale_rank
	FROM retail_sales
	GROUP BY sale_year, sale_month
) as best_month_per_year
WHERE sale_rank = 1

-- Retrieval of top 5 customers based on highest total sales 

SELECT 
	customer_id,
	SUM(total_sale) as total_sales
FROM retail_sales
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 5

-- Retrieval of number of unique customers who purchased items from each category

SELECT 
	category,
	COUNT(DISTINCT customer_id) as unique_customers_count
FROM retail_sales
GROUP BY category

-- Creation of each shift and number of orders (e.g. Morning <= 12, Afternoon 12-17, Evening > 17)

SELECT EXTRACT(HOUR FROM CURRENT_TIME)

WITH hourly_sales
AS 
(
	SELECT *, 
		CASE 
			WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
			WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
			ELSE 'Evening'
		END as shift
	FROM retail_sales
)
SELECT
	shift,
	COUNT(transactions_id) as total_orders
FROM hourly_sales
GROUP BY shift 












