USE imdb;

-- Q1. Find the total number of rows in each table of the schema?

SELECT table_name AS Table_Name,
table_rows AS no_of_rows
FROM information_schema.tables
WHERE table_schema='imdb';

-- Q2. Which columns in the movie table have null values?
SELECT SUM(CASE 
              WHEN id is NULL THEN 1
              ELSE 0
              END) AS id_nulls_count,
		SUM(CASE 
              WHEN title is NULL THEN 1
              ELSE 0
              END) AS title_nulls_count,
		SUM(CASE 
              WHEN id is NULL THEN 1
              ELSE 0
              END) AS id_nulls_count,
		SUM(CASE 
              WHEN year is NULL THEN 1
              ELSE 0
              END) AS year_nulls_count,
		SUM(CASE 
              WHEN date_published is NULL THEN 1
              ELSE 0
              END) AS date_published_nulls_count,
		SUM(CASE 
              WHEN duration is NULL THEN 1
              ELSE 0
              END) AS duration_nulls_count,
		SUM(CASE 
              WHEN country is NULL THEN 1
              ELSE 0
              END) AS country_nulls_count,
		SUM(CASE 
              WHEN worlwide_gross_income is NULL THEN 1
              ELSE 0
              END) AS worlwide_gross_income_nulls_count,
		SUM(CASE 
              WHEN languages is NULL THEN 1
              ELSE 0
              END) AS languages_nulls_count,
		SUM(CASE 
              WHEN production_company is NULL THEN 1
              ELSE 0
              END) AS production_company_nulls_count
FROM movie;

-- Q3. Find the total number of movies released each year? How does the trend look month wise?

SELECT year, COUNT(id) AS number_of_movies
FROM movie
GROUP BY year;

SELECT MONTH(date_published) AS month_num, COUNT(id) AS number_of_movies
FROM movie
GROUP BY MONTH(date_published)
ORDER BY number_of_movies DESC;

-- Q4. How many movies were produced in the USA or India in the year 2019??

SELECT COUNT(ID) AS number_of_movies FROM movie
WHERE year=2019
AND (country LIKE '%USA%' OR country LIKE '%India%');

-- Q5. Find the unique list of the genres present in the data set?
SELECT DISTINCT genre FROM genre;

-- Q6.Which genre had the highest number of movies produced overall?
SELECT genre, COUNT(movie_id) AS number_of_movies FROM genre
GROUP BY genre
ORDER BY number_of_movies DESC
LIMIT 1;

-- Q7. How many movies belong to only one genre?
WITH summary AS (
SELECT movie_id,COUNT(genre) AS genre_count FROM genre
GROUP BY movie_id
HAVING genre_count=1)
SELECT COUNT(movie_id) FROM summary;

-- Q8.What is the average duration of movies in each genre? 
SELECT genre,ROUND(AVG(duration),2) AS avg_duration FROM movie m
INNER JOIN genre g
ON m.id=g.movie_id
GROUP BY genre;

-- Q9.What is the rank of the ‘thriller’ genre of movies among all the genres in terms of number of movies produced? 
WITH summary AS (
SELECT genre,COUNT(movie_id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(movie_id) DESC) AS genre_rank
FROM movie m
INNER JOIN genre g
ON m.id=g.movie_id
GROUP BY genre)
SELECT * FROM summary
WHERE genre='Thriller';

-- Q10.  Find the minimum and maximum values in  each column of the ratings table except the movie_id column?
SELECT 
MIN(avg_rating) AS min_avg_rating,
MAX(avg_rating) AS max_avg_rating,
MIN(total_votes) AS min_total_votes,
MAX(total_votes) AS max_total_votes,
MIN(median_rating) AS min_median_rating,
MAX(median_rating) AS max_median_rating
FROM ratings;

-- Q11. Which are the top 10 movies based on average rating?
WITH summary AS (
SELECT title, avg_rating, 
RANK() OVER(ORDER BY avg_rating DESC) AS movie_rank
FROM movie m
INNER JOIN ratings r 
ON m.id=r.movie_id)
SELECT * FROM summary
WHERE movie_rank<=10;

-- Q12. Summarise the ratings table based on the movie counts by median ratings.

SELECT median_rating, COUNT(movie_id) AS movie_count FROM ratings
GROUP BY median_rating
ORDER BY median_rating;

-- Q13. Which production house has produced the most number of hit movies (average rating > 8)??
WITH summary AS (
SELECT production_company, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS prod_company_rank
FROM movie m
INNER JOIN ratings r 
ON m.id=r.movie_id
WHERE avg_rating>8
AND production_company IS NOT NULL
GROUP BY production_company)
SELECT * FROM summary
WHERE prod_company_rank=1;

-- Q14. How many movies released in each genre during March 2017 in the USA had more than 1,000 votes?

SELECT genre, COUNT(m.id) AS movie_count FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN genre g
ON m.id=g.movie_id
WHERE year='2017'
AND MONTH(date_published)='03'
AND country LIKE '%USA%'
AND total_votes>1000
GROUP BY genre
ORDER BY movie_count DESC;


-- Q15. Find movies of each genre that start with the word ‘The’ and which have an average rating > 8?

SELECT title, avg_rating,genre FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN genre g
ON m.id=g.movie_id
WHERE title LIKE 'The%'
AND avg_rating>8
ORDER BY avg_rating DESC;

-- Q16. Of the movies released between 1 April 2018 and 1 April 2019, how many were given a median rating of 8?
SELECT COUNT(m.id) AS movie_count FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
WHERE date_published BETWEEN '2018-04-01' AND '2019-04-01'
AND median_rating=8;

-- Q19. Who are the top three directors in the top three genres whose movies have an average rating > 8?
WITH top_three_genres AS (
SELECT genre, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS genre_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN genre g
ON m.id=g.movie_id
WHERE avg_rating>8
GROUP BY genre
LIMIT 3), top_three_directors AS (
SELECT name AS director_name, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS movie_rank 
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN genre g
ON m.id=g.movie_id
INNER JOIN director_mapping dm 
ON dm.movie_id=m.id
INNER JOIN names n
ON n.id=dm.name_id
WHERE genre IN (SELECT genre FROM top_three_genres)
AND avg_rating>8
GROUP BY director_name)
SELECT director_name, movie_count FROM top_three_directors
WHERE movie_rank<=3;

USE imdb;

SHOW VARIABLES LIKE 'sql_mode';
SET global sql_mode='';

-- Q17. Do German movies get more votes than Italian movies? 

WITH votes_summary AS (
SELECT languages, SUM(total_votes) AS total_votes FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
WHERE languages LIKE '%GERMAN%'
UNION
SELECT languages, SUM(total_votes) AS total_votes FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
WHERE languages LIKE '%ITALIAN%'), languages_summary AS (
SELECT languages FROM votes_summary
ORDER BY total_votes DESC
LIMIT 1)
SELECT IF(languages LIKE 'GERMAN', 'YES', 'NO') AS answer
FROM languages_summary;

-- Q20. Who are the top two actors whose movies have a median rating >= 8?
SELECT n.name AS actor_name, COUNT(r.movie_id) AS movie_count FROM ratings r
INNER JOIN role_mapping rm
ON r.movie_id=rm.movie_id
INNER JOIN names n
ON n.id=rm.name_id
WHERE median_rating>=8
AND category='actor'
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 2;

-- Q21. Which are the top three production houses based on the number of votes received by their movies?
WITH summary AS (
SELECT production_company,SUM(total_votes) AS vote_count, 
RANK() OVER(ORDER BY SUM(total_votes) DESC) AS prod_comp_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
GROUP BY production_company)
SELECT * FROM summary
WHERE prod_comp_rank<=3;

-- Q22. Rank actors with movies released in India based on their average ratings. Which actor is at the top of the list?
-- Note: The actor should have acted in at least five Indian movies. 
-- (Hint: You should use the weighted average based on votes. If the ratings clash, then the total number of votes should act as the tie breaker.)
SELECT n.name AS actor_name, total_votes, COUNT(m.id) AS movie_count, 
ROUND((SUM(avg_rating*total_votes)/SUM(total_votes)),2) AS actor_avg_rating,
RANK() OVER(ORDER BY SUM(avg_rating*total_votes)/SUM(total_votes) DESC) AS actor_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN role_mapping rm
ON r.movie_id=rm.movie_id
INNER JOIN names n
ON n.id=rm.name_id
WHERE category='actor'
AND country LIKE '%INDIA%'
GROUP BY n.name
HAVING movie_count>=5;

-- Q23.Find out the top five actresses in Hindi movies released in India based on their average ratings? 
-- Note: The actresses should have acted in at least three Indian movies. 
-- (Hint: You should use the weighted average based on votes. If the ratings clash, then the total number of votes should act as the tie breaker.)
SELECT n.name AS actress_name, total_votes, COUNT(m.id) AS movie_count, 
ROUND((SUM(avg_rating*total_votes)/SUM(total_votes)),2) AS actress_avg_rating,
RANK() OVER(ORDER BY SUM(avg_rating*total_votes)/SUM(total_votes) DESC) AS actress_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN role_mapping rm
ON r.movie_id=rm.movie_id
INNER JOIN names n
ON n.id=rm.name_id
WHERE category='actress'
AND country LIKE '%INDIA%'
AND languages LIKE 'HINDI%'
GROUP BY n.name
HAVING movie_count>=3;

USE imdb;

/* Q24. Select thriller movies as per avg rating and classify them in the following category: 

			Rating > 8: Superhit movies
			Rating between 7 and 8: Hit movies
			Rating between 5 and 7: One-time-watch movies
			Rating < 5: Flop movies
--------------------------------------------------------------------------------------------*/
WITH summary AS(
SELECT title,avg_rating FROM movie m
INNER JOIN genre g
ON m.id=g.movie_id
INNER JOIN ratings r 
ON g.movie_id=r.movie_id
WHERE genre='Thriller')
SELECT *, 
CASE
    WHEN avg_rating>8 THEN 'Superhit movie'
    WHEN avg_rating>=7 AND avg_rating<=8 THEN 'Hit Movie'
    WHEN avg_rating>=5 AND avg_rating<7 THEN 'One-time-watch movie'
    ELSE 'Flop Movie'
END AS avg_rating_description
FROM summary;

-- Q25. What is the genre-wise running total and moving average of the average movie duration? 
SELECT genre,ROUND(AVG(duration),2) AS avg_duration, 
SUM(AVG(duration)) OVER(ORDER BY genre ROWS UNBOUNDED PRECEDING) AS running_total_duration,
AVG(AVG(duration)) OVER(ORDER BY genre ROWS UNBOUNDED PRECEDING) AS moving_avg_duration
FROM movie m
INNER JOIN genre g
ON m.id=g.movie_id
GROUP BY genre;

-- Q26. Which are the five highest-grossing movies of each year that belong to the top three genres? 
WITH top_three_genres AS (
SELECT genre, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS genre_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
INNER JOIN genre g
ON m.id=g.movie_id
GROUP BY genre
LIMIT 3), movie_summary AS(
SELECT genre, year, title AS movie_name,
CAST((REPLACE(IFNULL(worlwide_gross_income,0),'$ ',''))AS DECIMAL(10)) AS worldwide_gross_income,
RANK() OVER(PARTITION BY year ORDER BY CAST((REPLACE(IFNULL(worlwide_gross_income,0),'$',''))AS DECIMAL(10)) DESC) AS movie_rank
FROM movie m
INNER JOIN genre g
ON m.id=g.movie_id
WHERE genre IN (SELECT genre FROM top_three_genres))
SELECT * FROM movie_summary
WHERE movie_rank<=5;

USE imdb;

-- Q27.  Which are the top two production houses that have produced the highest number of hits (median rating >= 8) among multilingual movies?
WITH movie_summary AS (
SELECT production_company, COUNT(m.id) AS movie_count, 
RANK() OVER(ORDER BY COUNT(m.id) DESC) AS prod_comp_rank
FROM movie m
INNER JOIN ratings r
ON m.id=r.movie_id
WHERE median_rating>=8
AND POSITION(',' IN languages)>0
AND production_company IS NOT NULL
GROUP BY production_company)
SELECT * FROM movie_summary
WHERE prod_comp_rank<3;

-- Q28. Who are the top 3 actresses based on number of Super Hit movies (average rating >8) in drama genre?
WITH summary AS (
SELECT name AS actress_name, SUM(total_votes) AS total_votes, COUNT(r.movie_id) AS movie_count,
ROUND(SUM(avg_rating*total_votes)/SUM(total_votes),2) AS actress_avg_rating,
RANK() OVER(ORDER BY COUNT(r.movie_id) DESC) AS actress_rank
FROM genre g 
INNER JOIN ratings r
ON g.movie_id=r.movie_id
INNER JOIN role_mapping rm 
ON rm.movie_id=r.movie_id
INNER JOIN names n
ON n.id=rm.name_id
WHERE category='actress'
AND avg_rating>8
AND genre='Drama'
GROUP BY name)
SELECT * FROM summary
WHERE actress_rank<=3;