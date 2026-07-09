-- Database Creation

CREATE DATABASE zomato_data_analysis;

DROP TABLE IF EXISTS deliveries; 
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS riders;

CREATE TABLE restaurants(
					restaurant_id SERIAL PRIMARY KEY,
					restaurant_name VARCHAR(100) NOT NULL,
					city VARCHAR(50),
					opening_hours VARCHAR(50));

CREATE TABLE customers(
					customer_id SERIAL PRIMARY KEY,
					customer_name VARCHAR(100) NOT NULL,
					reg_date DATE);

CREATE TABLE riders(
				rider_id SERIAL PRIMARY KEY,
				rider_name VARCHAR(100) NOT NULL, 
				sign_up DATE);

CREATE TABLE orders(
				order_id SERIAL PRIMARY KEY,
				customer_id INT,
				restaurant_id INT,
				order_item VARCHAR(255),
				order_date DATE NOT NULL,
				order_time TIME,
				order_status VARCHAR(20) DEFAULT 'Pending',
				total_amount DECIMAL(10, 2) NOT NULL,
				FOREIGN KEY (customer_id) REFERENCES customers(customer_id), 
				FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id));

CREATE TABLE deliveries(
					delivery_id SERIAL PRIMARY KEY,
					order_id INT,
					delivery_status VARCHAR(20) DEFAULT 'Pending',
					delivery_time TIME,
					rider_id INT,
					FOREIGN KEY (order_id) REFERENCES orders(order_id),
					FOREIGN KEY (rider_id) REFERENCES riders(rider_id));

SELECT * FROM riders;
SELECT * FROM restaurants;
SELECT * FROM customers;
SELECT * FROM orders;
SELECT * FROM deliveries;


-- Data Analysis

-- Find top 5 most ordered dishes by customer 'Arjun Mehta' in past 3 years

SELECT
	customer_id,
	customer_name,
	dishes,
	total_orders
FROM 
	(SELECT 
		c.customer_id,
		c.customer_name, 
		o.order_item AS dishes,
		COUNT(*) AS total_orders,
		DENSE_RANK() OVER(ORDER BY COUNT(*) DESC) AS rank
	FROM orders AS o
	JOIN customers AS c
	ON c.customer_id = o.customer_id
	WHERE 
		o.order_date >= CURRENT_DATE - INTERVAL '3 Year'
		AND
		c.customer_name = 'Arjun Mehta'
	GROUP BY 1, 2, 3
	ORDER BY 1, 4 DESC) AS t1
WHERE rank <= 5

-- Identify time slots during which most orders are placed based on 2-hour intervals

SELECT
    CASE
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 0 AND 1 THEN '00:00 - 02:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 2 AND 3 THEN '02:00 - 04:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 4 AND 5 THEN '04:00 - 06:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 6 AND 7 THEN '06:00 - 08:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 8 AND 9 THEN '08:00 - 10:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 10 AND 11 THEN '10:00 - 12:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 12 AND 13 THEN '12:00 - 14:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 14 AND 15 THEN '14:00 - 16:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 16 AND 17 THEN '16:00 - 18:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 18 AND 19 THEN '18:00 - 20:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 20 AND 21 THEN '20:00 - 22:00'
        WHEN EXTRACT(HOUR FROM order_time) BETWEEN 22 AND 23 THEN '22:00 - 00:00'
    END AS time_slot,
    COUNT(order_id) AS order_count
FROM Orders
GROUP BY time_slot
ORDER BY order_count DESC;

SELECT
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 AS start_time,
	FLOOR(EXTRACT(HOUR FROM order_time) / 2) * 2 + 2 AS end_time,
	COUNT(*) AS total_orders
FROM orders
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Find the average order value per customer who has placed more than 750 orders

SELECT 
	c.customer_name,
	AVG(o.total_amount) AS average_order_value,
	COUNT(o.order_id) AS total_orders
FROM orders AS o
JOIN customers AS c
ON c.customer_id = o.customer_id
GROUP BY 1
HAVING COUNT(o.order_id) > 750;

-- List the customers who have spent more than 100K in total on food orders

SELECT
	c.customer_name,
	SUM(o.total_amount) AS total_spent
FROM orders AS o
JOIN customers AS c
ON c.customer_id = o.customer_id
GROUP BY 1
HAVING SUM(o.total_amount) > 100000;

-- Find orders that were placed but not delivered
-- Return each restuarant name, city and number of not delivered orders 

SELECT 
	r.restaurant_name,
	COUNT(o.order_id) AS count_of_undelivered_orders
FROM orders AS o
LEFT JOIN restaurants AS r
ON r.restaurant_id = o.restaurant_id
LEFT JOIN deliveries AS d
ON d.order_id = o.order_id
WHERE d.delivery_id IS NULL
GROUP BY 1
ORDER BY 2 DESC;

SELECT
	r.restaurant_name,
	COUNT(o.order_id) AS count_of_undelivered_orders
FROM orders AS o
LEFT JOIN restaurants AS r
ON r.restaurant_id = o.restaurant_id
WHERE o.order_id NOT IN (SELECT order_id FROM deliveries)
GROUP BY 1
ORDER BY 2 DESC;

-- Rank restaurants by their total revenue from the past 4 years
-- Include their name, total revenue and rank within their city

WITH rank_table 
AS
	(SELECT 
		r.city,
		r.restaurant_name,
		SUM(o.total_amount) AS total_revenue,
		RANK() OVER(PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS rank
	FROM orders AS o
	JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
	WHERE o.order_date >= CURRENT_DATE - INTERVAL '4 Year'
	GROUP BY 1, 2)
SELECT 
	*
FROM rank_table
WHERE rank = 1

-- Identify the most popular dish in each city based on number of orders

SELECT *
FROM
	(SELECT 
		r.city, 
		o.order_item AS dish,
		COUNT(order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.city ORDER BY COUNT(order_id) DESC) AS rank
	FROM orders AS o
	JOIN restaurants AS r
	ON r.restaurant_id = o.restaurant_id
	GROUP BY 1, 2) AS t1
WHERE rank = 1

-- Find customers who haven’t placed an order in 2024 but did in 2023

SELECT 
	DISTINCT c.customer_id,
	c.customer_name
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
WHERE 
	EXTRACT(YEAR FROM o.order_date) = 2023
	AND 
	c.customer_id NOT IN (SELECT DISTINCT customer_id FROM orders 
						WHERE EXTRACT(YEAR FROM order_date) = 2024)

-- Calculate order cancellation rate for each restaurant between 2023 and 2024

WITH cancellation_ratio_2023 AS
	(SELECT 
		o.restaurant_id,
		COUNT(o.order_id) AS total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM orders AS o
	LEFT JOIN deliveries AS d
	ON o.order_id = d.order_id
	WHERE EXTRACT(YEAR FROM o.order_date) = 2023
	GROUP BY o.restaurant_id)
,
cancellation_ratio_2024 AS
	(SELECT
		o.restaurant_id,
		COUNT(o.order_id) AS total_orders,
		COUNT(CASE WHEN d.delivery_id IS NULL THEN 1 END) AS not_delivered
	FROM orders AS o
	LEFT JOIN deliveries AS d
	ON o.order_id = d.order_id
	WHERE EXTRACT(YEAR FROM o.order_date) = 2024
	GROUP BY o.restaurant_id)
,
data_2023 AS
	(SELECT
		restaurant_id,
		total_orders,
		not_delivered,
		ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancellation_ratio_2023
	FROM cancellation_ratio_2023)
,
data_2024 AS
	(SELECT
		restaurant_id,
		total_orders,
		not_delivered,
		ROUND((not_delivered::numeric / total_orders::numeric) * 100, 2) AS cancellation_ratio_2024
	FROM cancellation_ratio_2024)

SELECT 
	d24.restaurant_id AS restaurant_id,
	d24.cancellation_ratio_2024 AS cancellation_ratio_2024,
	d23.cancellation_ratio_2023 AS cancellation_ratio_2023
FROM data_2024 AS d24
JOIN data_2023 AS d23
ON d24.restaurant_id = d23.restaurant_id;
	
-- Determine each rider's average delivery time

SELECT
    o.order_id,
    o.order_time,
    d.delivery_time
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
ORDER BY RANDOM()
LIMIT 20;

SELECT 
	o.order_id, 
	o.order_time,
	d.delivery_time,
	d.rider_id,
	CASE 
		WHEN d.delivery_time >= o.order_time
			THEN d.delivery_time - o.order_time
		ELSE
			d.delivery_time - o.order_time + INTERVAL '1 day'
		END AS time_difference,
	EXTRACT(
		EPOCH FROM CASE WHEN d.delivery_time >= o.order_time
							THEN d.delivery_time - o.order_time
						ELSE
							d.delivery_time - o.order_time + INTERVAL '1 day'
						END) / 60 AS time_difference_minutes
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
WHERE d.delivery_status = 'Delivered'
ORDER BY o.order_id;

-- Calculate each restaurant's growth ratio based on total number of delivered orders since its joining

WITH growth_ratio
AS
	(SELECT 
		o.restaurant_id,
		TO_CHAR(o.order_date, 'mm-yy') AS month_name,
		COUNT(o.order_id) AS current_month_orders,
		LAG(COUNT(o.order_id), 1) OVER(PARTITION BY o.restaurant_id ORDER BY TO_CHAR(o.order_date, 'mm-yy')) AS previous_month_orders
	FROM orders AS o
	JOIN deliveries AS d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'
	GROUP BY 1, 2
	ORDER BY 1, 2)
SELECT 
	restaurant_id,
	month_name,
	previous_month_orders,
	current_month_orders,
	ROUND((current_month_orders::numeric - previous_month_orders::numeric) / (previous_month_orders::numeric) * 100, 2) AS growth_ratio
FROM growth_ratio;

-- Segment customers into 'Gold' or 'Silver' groups based on their total spending compared to the average order value
-- If a customer's total spending exceeds the AOV, label them as 'Gold'; otherwise, label them as 'Silver'
-- Determine each segment's total number of orders and total revenue

SELECT AVG(total_amount) FROM orders;

SELECT
	customer_category,
	SUM(total_orders) AS total_orders,
	SUM(total_spent) AS total_revenue
FROM
	(SELECT 
		customer_id,
		SUM(total_amount) AS total_spent,
		COUNT(order_id) AS total_orders,
		CASE 
			WHEN SUM(total_amount) > (SELECT AVG(customer_total) FROM (SELECT SUM(total_amount) AS customer_total 
																		FROM orders
																		GROUP BY customer_id) 
																		
																		AS avg_customer) 
																		
																		THEN 'Gold'
			ELSE 'Silver'
		END AS customer_category
	FROM orders
	GROUP BY 1) AS t1
GROUP BY 1;

-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount

SELECT 
	d.rider_id,
	TO_CHAR(o.order_date, 'mm-yy') AS month,
	SUM(total_amount) AS business_revenue,
	SUM(total_amount) * 0.08 AS riders_earning
FROM orders AS o
JOIN deliveries AS d
ON o.order_id = d.order_id
GROUP BY 1, 2
ORDER BY 1, 2;

-- Find the number of 5-star, 4-star and 3-star ratings each rider has based on delivery time
-- If orders are delivered less than 15 minutes of order received time, the rider get 5 star rating
-- If orders are delivered between 15 and 20 minutes, they get 4 star rating 
-- If orders are delivered after 20 minutes, they get 3 star rating

SELECT
	rider_id, 
	stars,
	COUNT(*) AS total_stars
FROM
	(
	SELECT 
		rider_id,
		elapsed_delivery,
		CASE 
			WHEN elapsed_delivery < 15 THEN '5 star'
			WHEN elapsed_delivery BETWEEN 15 AND 20 THEN '4 star'
			ELSE '3 star'
		END AS stars
	FROM
		(SELECT 
			o.order_id,
			o.order_time,
			d.delivery_time,
			EXTRACT(EPOCH FROM(d.delivery_time - o.order_time +
								CASE WHEN d.delivery_time < o.order_time 
										THEN INTERVAL '1 day'
										ELSE INTERVAL '0 day'
								END)) / 60 AS elapsed_delivery,
			d.rider_id
		FROM orders AS o
		JOIN deliveries AS d
		ON o.order_id = d.order_id
		WHERE d.delivery_status = 'Delivered') AS t1
	) AS t2
GROUP BY 1, 2
ORDER BY 1, 3 DESC;
	
-- Analyse order frequency per day of the week and identify the peak day for each restaurant

SELECT * 
FROM
	(SELECT	
		r.restaurant_name,
		TO_CHAR(o.order_date, 'Day') AS day,
		COUNT(o.order_id) AS total_orders,
		RANK() OVER(PARTITION BY r.restaurant_name ORDER BY COUNT(o.order_id) DESC) AS rank
	FROM orders AS o
	JOIN restaurants AS r
	ON o.restaurant_id = r.restaurant_id
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC) AS t1
WHERE rank = 1

-- Calculate the total revenue generated by each customer over all their orders

SELECT
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) AS customer_lifetime_value
FROM orders AS o
JOIN customers AS c
ON o.customer_id = c.customer_id
GROUP BY 1, 2;

-- Identify sales trends by comparing each month's total sales to the previous month

SELECT 
	EXTRACT(YEAR FROM order_date) AS year,
	EXTRACT(MONTH FROM order_date) AS month,
	SUM(total_amount) AS total_sales,
	LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) AS previous_month_sales
FROM orders
GROUP BY 1, 2;

-- Evaluate rider efficiency by determining average delivery times
-- Identify those with lowest and highest averages

WITH rider_efficiency
AS
	(SELECT 
		d.rider_id AS rider_id,
		EXTRACT(EPOCH FROM (d.delivery_time - o.order_time +
				CASE WHEN d.delivery_time < o.order_time 
						THEN INTERVAL '1 day'
						ELSE INTERVAL '0 day'
				END)) / 60 AS elapsed_delivery
	FROM orders AS o
	JOIN deliveries AS d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered')
,
riders_time
AS
	(SELECT
		rider_id,
		AVG(elapsed_delivery) AS average_time
	FROM rider_efficiency
	GROUP BY 1)
SELECT 
	MIN(average_time),
	MAX(average_time)
FROM riders_time;

-- Track the popularity of specific order items over time and identify seasonal demand spikes

SELECT
	order_item,
	season,
	COUNT(order_id) AS total_orders	
FROM
	(SELECT 
		*,
		EXTRACT(MONTH FROM order_date) AS month,
		CASE 
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 3 AND 6 THEN 'Spring'
			WHEN EXTRACT(MONTH FROM order_date) > 6 AND EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
			WHEN EXTRACT(MONTH FROM order_date) > 8 AND EXTRACT(MONTH FROM order_date) < 12 THEN 'Autumn'
			ELSE 'Winter'
		END AS season
	FROM orders) AS t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

-- Rank each city based on the total revenue for year 2023

SELECT 
	r.city,
	SUM(total_amount) AS total_revenue,
	RANK() OVER(ORDER BY SUM(total_amount) DESC) AS city_rank
FROM orders AS o
JOIN restaurants AS r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1;
