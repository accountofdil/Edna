-- Database Creation

CREATE DATABASE spotify_data_analysis

DROP TABLE IF EXISTS spotify;
CREATE TABLE spotify (
				    artist VARCHAR(255),
				    track VARCHAR(255),
				    album VARCHAR(255),
				    album_type VARCHAR(50),
				    danceability FLOAT,
				    energy FLOAT,
				    loudness FLOAT,
				    speechiness FLOAT,
				    acousticness FLOAT,
				    instrumentalness FLOAT,
				    liveness FLOAT,
				    valence FLOAT,
				    tempo FLOAT,
				    duration_min FLOAT,
				    title VARCHAR(255),
				    channel VARCHAR(255),
				    views FLOAT,
				    likes BIGINT,
				    comments BIGINT,
				    licensed BOOLEAN,
				    official_video BOOLEAN,
				    stream BIGINT,
				    energy_liveness FLOAT,
				    most_played_on VARCHAR(50));

SELECT * FROM spotify;

SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT album) FROM spotify;
SELECT COUNT(DISTINCT artist) FROM spotify;
SELECT DISTINCT album_type FROM spotify;
SELECT DISTINCT channel FROM spotify;
SELECT DISTINCT most_played_on FROM spotify;

SELECT MAX(duration_min) FROM spotify;
SELECT MIN(duration_min) FROM spotify;

SELECT * FROM spotify
WHERE duration_min = 0;

DELETE FROM spotify 
WHERE duration_min = 0;
SELECT * FROM spotify
WHERE duration_min = 0;

SELECT COUNT(*) FROM spotify;


-- Data Analysis

-- Retrieve the names of all tracks that have over 1 billion streams

SELECT * FROM spotify
WHERE stream > 1000000000;

-- List all albums along with their respective artists

SELECT
	DISTINCT(album),
	artist
FROM spotify
ORDER BY 1;

-- Get the total number of comments for tracks where licensed = TRUE

SELECT 
	SUM(comments)
FROM spotify
WHERE licensed = 'true';

-- Find all tracks that belong to the album type single

SELECT *
FROM spotify
WHERE album_type ILIKE 'single';

-- Count the total number of tracks by each artist

SELECT 
	artist,
	COUNT(*) as total_no_songs
FROM spotify
GROUP BY artist
ORDER BY 2 DESC;

-- Calculate the average danceability of tracks in each album

SELECT 
	album,
	AVG(danceability) as avg_danceability
FROM spotify
GROUP BY 1
ORDER BY 2 DESC;

-- Find the top 100 tracks with the highest energy values

SELECT
	track,
	AVG(energy)
FROM spotify
GROUP BY 1
ORDER BY 2 DESC
LIMIT 100;

-- List all tracks along with their views and likes where official_video = TRUE

SELECT
	track,
	SUM(views) as total_views,
	SUM(likes) as total_likes
FROM spotify
WHERE official_video = 'true'
GROUP BY 1
ORDER BY 2 DESC;

SELECT
	track,
	SUM(views) as total_views,
	SUM(likes) as total_likes
FROM spotify
WHERE official_video = 'true'
GROUP BY 1
ORDER BY 3 DESC;

-- For each album, calculate the total views of all associated tracks

SELECT 
	album,
	track,
	SUM(views) as total_views
FROM spotify
GROUP BY 1, 2
ORDER BY 3 DESC;

-- Retrieve the track names that have been streamed on Spotify more than YouTube

SELECT * FROM
	(SELECT 
		track,
		COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END), 0) as streamed_on_youtube,
		COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END), 0) as streamed_on_spotify
	FROM spotify
	GROUP BY 1) as t1
WHERE 
	streamed_on_spotify > streamed_on_youtube
	AND
	streamed_on_youtube <> 0;

-- Find the top 3 most-viewed tracks for each artist using window functions

WITH track_ranking_artists
AS
	(SELECT 
		artist, 
		track,
		SUM(views) as total_views,
		DENSE_RANK() OVER(PARTITION BY artist ORDER BY SUM(views) DESC) as rank
	FROM spotify
	GROUP BY 1, 2
	ORDER BY 1, 3 DESC)
SELECT * 
FROM track_ranking_artists
WHERE rank <= 3;

-- Find tracks where the liveness score is above the average

SELECT 
	track,
	liveness
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify);

-- Calculate the difference between the highest and lowest energy values for tracks in each album

WITH max_min_energy
AS
	(SELECT 
		album,
		MAX(energy) as max_energy,
		MIN(energy) as min_energy
	FROM spotify
	GROUP BY 1)
SELECT 
	album,
	max_energy,
	min_energy,
	max_energy - min_energy as energy_difference
FROM max_min_energy
ORDER BY 4 DESC;


-- Query Optimisation

EXPLAIN ANALYZE
SELECT 
	artist,
	track,
	views
FROM spotify
WHERE 
	artist = 'Gorillaz'
	AND most_played_on = 'Youtube'
ORDER BY stream DESC 
LIMIT 25;

CREATE INDEX artist_index ON spotify (artist);

EXPLAIN ANALYZE
SELECT 
	artist,
	track,
	views
FROM spotify
WHERE 
	artist = 'Gorillaz'
	AND most_played_on = 'Youtube'
ORDER BY stream DESC 
LIMIT 25;
