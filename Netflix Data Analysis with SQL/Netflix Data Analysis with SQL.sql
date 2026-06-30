-- Database Creation

CREATE DATABASE netflix_data_analysis;

DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix(
					show_id VARCHAR(10),
					type VARCHAR(10),
					title VARCHAR(150),
					director VARCHAR(250),
					casts VARCHAR(800),
					country VARCHAR(150),
					date_added VARCHAR(50),
					release_year INT,
					rating VARCHAR(10),
					duration VARCHAR(15),
					listed_in VARCHAR(250),
					description VARCHAR(550));

SELECT * FROM netflix;

SELECT 
	COUNT(*) as total_content
FROM netflix;

SELECT
	DISTINCT type
FROM netflix;


-- Data Analysis

-- Count the number of movies versus TV shows

SELECT 
	type,
	COUNT(*) as total_content
FROM netflix
GROUP BY type

-- Find the most common rating for movies and TV shows

SELECT 
	type,
	rating
FROM
	(SELECT
		type,
		rating,
		COUNT(*),
		RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) as ranking
	FROM netflix
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC) as t1
WHERE ranking = 1

-- List all movies released in a specific year (e.g. 2020)

SELECT * FROM netflix
WHERE 
	type = 'Movie'
	AND
	release_year = 2020

-- Find the top 5 countries with the most content on Netflix

SELECT 
	UNNEST(STRING_TO_ARRAY(country, ',')) as new_country,
	COUNT(show_id) as total_content
FROM netflix
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5

-- Identify the longest movie

SELECT * FROM netflix
WHERE 
	type = 'Movie'
	AND 
	duration = (SELECT MAX(duration) FROM netflix)

-- Find content added in the last 5 years

SELECT 
	*
FROM netflix
WHERE 
	TO_DATE(date_added, 'Month DD, YYYY') >= CURRENT_DATE - INTERVAL '5 years' 

-- Find all the movies and TV shows by director Rajiv Chilaka

SELECT * FROM netflix
WHERE director ILIKE '%Rajiv Chilaka%'

-- List all TV shows with more than 5 seasons

SELECT 
	*
FROM netflix
WHERE 
	type = 'TV Show'
	AND
	SPLIT_PART(duration, ' ', 1)::numeric > 5 

-- Count the number of content items in each genre

SELECT 
	UNNEST(STRING_TO_ARRAY(listed_in, ',')) as genre,
	COUNT(show_id) as total_content
FROM netflix
GROUP BY 1

-- Find each year and average numbers of content release in India on netflix
-- Return top 5 year with highest average content release

SELECT 
	EXTRACT(YEAR FROM TO_DATE(date_added, 'Month DD, YYYY')) as year,
	COUNT(*) as yearly_content,
	ROUND(COUNT(*)::numeric / (SELECT COUNT(*) FROM netflix WHERE country = 'India')::numeric * 100, 2) as avg_content_per_year
FROM netflix
WHERE country = 'India'
GROUP BY 1
ORDER BY 3 DESC
LIMIT 5

-- List all movies that are documentaries

SELECT * FROM netflix
WHERE listed_in ILIKE '%documentaries%'

-- Find all content without a director

SELECT * FROM netflix
WHERE director IS NULL

-- Find how many movies actor Salman Khan appeared in last 10 years

SELECT * FROM netflix
WHERE 
	casts ILIKE '%Salman Khan%'
	AND
	release_year > EXTRACT(YEAR FROM CURRENT_DATE) - 10

-- Find top 10 actors who have appeared in highest number of movies produced in India

SELECT 
	UNNEST(STRING_TO_ARRAY(casts, ',')) as actors,
	COUNT(*) as total_content
FROM netflix
WHERE country ILIKE '%India%'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10

-- Categorise the content based on keywords 'kill' and 'violence' in the description field 
-- Label content containing these keywords as 'Bad' and all other content as 'Good'
-- Count the number of items that fall into each category

WITH count_of_content_type
AS(
	SELECT *,
		CASE
		WHEN description ILIKE '%kill%' OR 
				description ILIKE '%violence%' THEN 'Bad'
		ELSE 'Good'
		END content_type
	FROM netflix)
SELECT 
	content_type,
	COUNT(*) as total_content
FROM count_of_content_type
GROUP BY 1
	