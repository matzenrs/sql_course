-- Question #1: What columns does the [Survey] table have? --
SELECT * -- Selects all the columns --
FROM survey -- clarifies the table to pull from --
LIMIT 10; -- Limits the number of rows to 10 -- 

-- Question #2: What is the number of responses for each question? --
/* We want to GROUP BY the questions column and use the aggregating COUNT function 
so that we can see the total number of users that completed each given question in the survey */
SELECT question, COUNT(DISTINCT user_id) AS  users_responded -- Select the question column and a count of the number of unique users who responded to each question --
FROM survey -- specifiying that we want to select the above columns from the survey table --
GROUP BY 1; -- Groups by the first parameter in the Select Command (question)
 
 -- Question #3: What questions have lower completion rates? -- 
SELECT question, COUNT(DISTINCT user_id) AS  users_responded -- Select the question column and a count of the number of unique users who responded to each question --
FROM survey -- specifiying that we want to select the above columns from the survey table --
GROUP BY 1; -- Groups by the first parameter in the Select Command (question)
 
 -- Question #4: What might be the reason for lower completion rates? -- 
WITH funnel_progress AS (SELECT user_id, COUNT(user_id) AS number_answered -- defining parameters of temporary table called funnel_progress --
FROM survey -- specifying that we want to select the columns that will make up the temporary table from the survey table
GROUP BY 1 -- grouping by the user_id
ORDER BY 2 DESC) -- ordering the results based on number of occurances of the ids
 
SELECT response, COUNT(survey.user_id) AS num_response /* use AS clause to 'clean up' column name*/, survey.user_id AS user_id -- specifying the columns to be selected
FROM survey -- specifying the table from which we will select the columns mentioned above
JOIN funnel_progress ON funnel_progress.user_id = survey.user_id -- use the primary key, user_id, to join the two tables 
WHERE question LIKE '3%' AND number_answered = 4 -- use the WHERE clause to filter for values in the question column that contain 3 and for values in the number_answered column that equal 4
GROUP BY 1 -- group by the response column
ORDER BY 2 DESC; -- order by the number of responses

--Question #5: What are the column names (of the three tables)? --
-- quiz table SELECT statement
SELECT *
FROM quiz
LIMIT 5;
-- home_try_on table SELECT statement
SELECT *
FROM home_try_on
LIMIT 5;
-- purchase table SELECT statement
SELECT *
FROM purchase
LIMIT 5;

--Question #6: What are the overall conversion rates for the funnel?
--Question #7: How do conversion rates compare on a step-by-step basis?

--Intermediate query--
SELECT DISTINCT q.user_id, -- select unique (no dupes) quiz table user_id
   h.user_id IS NOT NULL AS 'is_home_try_on', -- select home_try_on table user_id where they are not blank
   h.number_of_pairs, -- select the number of pairs from the home_try_on table
   p.user_id IS NOT NULL AS 'is_purchase' -- select the purchase table user_id
FROM quiz AS 'q'-- giving quiz the alias 'q' (same pattern goes for other similar steps below)
LEFT JOIN home_try_on AS 'h'
   ON q.user_id = h.user_id -- join the tables on the shared attribute, user_id
LEFT JOIN purchase AS 'p'
   ON p.user_id = q.user_id -- see above comment
LIMIT 10; -- just trying to get an idea for what this looks like, so limiting to 10 rows

--Conversion metrics query-- 
WITH funnels AS (SELECT DISTINCT q.user_id, h.user_id IS NOT NULL AS 'is_home_try_on', h.number_of_pairs, p.user_id IS NOT NULL AS 'is_purchase'
-- above WITH + SELECT statement clarifies the columns to select --
FROM quiz AS 'q' -- giving quiz an alias, 'q' // same goes for other similar steps below
LEFT JOIN home_try_on AS 'h'
	ON q.user_id = h.user_id -- LEFT joining quiz and home_try_on tables
LEFT JOIN purchase AS 'p'
	ON p.user_id = q.user_id) -- LEFT joining purchase and quiz tables

SELECT COUNT(user_id) AS 'num_quiz', SUM(is_home_try_on) AS 'home_try_on', 
SUM(is_purchase) AS 'purchase_complete', 1.0 * SUM(is_home_try_on) / COUNT(user_id) AS 'try_on rate', -- multiplying results by 1 to show integer value
1.0 * SUM(is_purchase) / SUM(is_home_try_on) AS 'purchase rate', 
1.0 * SUM(is_purchase) / COUNT(user_ID) AS 'full_conversion'
FROM funnels;

-- Question #8: HOw do the 3-pair and 5-pair tests' conversion rates compare?
-- Question #9 (the big question): Are useres who receive more try-on pairs more likely to purchase?

WITH funnels AS (SELECT DISTINCT q.user_id, h.user_id IS NOT NULL AS 'is_home_try_on', h.number_of_pairs, 
								 p.user_id IS NOT NULL AS 'is_purchase', p.price
FROM quiz AS 'q'
LEFT JOIN home_try_on AS 'h'
	ON q.user_id = h.user_id
LEFT JOIN purchase AS 'p'
	ON p.user_id = q.user_id)

SELECT number_of_pairs, SUM(is_home_try_on) AS 'home_try_on', SUM(is_purchase) AS 'purchase_complete', 
1.0 * SUM(is_purchase) / SUM(is_home_try_on) AS 'purchase rate', 
ROUND(AVG(price),2) AS avg_price -- used ROUND function to truncate the decimal to 2 decimal places
FROM funnels
WHERE number_of_pairs = '3 pairs' -- only concerned with users who reached ‘home-try-on’ and the resulting A/B test participation
	OR number_of_pairs = '5 pairs' -- only concerned with users who reached ‘home-try-on’ and the resulting A/B test participation
GROUP BY number_of_pairs; -- want to compare between the test groups

-- Extras: Other areas of potential funnel optimization
/*curious to know whether any particular pattern could be found within the quiz responses that 
might be indicative of a greater propensity to purchase and/or a greater propensity to purchase a higher-priced pair of glasses*/

WITH funnels AS (SELECT q.user_id, h.user_id IS NOT NULL AS 'is_home_try_on', 
								 h.number_of_pairs, 
								 p.user_id IS NOT NULL AS 'is_purchase', q.fit, p.price
FROM quiz AS 'q'
LEFT JOIN home_try_on AS 'h'
	ON q.user_id = h.user_id
LEFT JOIN purchase AS 'p'
	ON p.user_id = q.user_id)
  
SELECT fit, SUM(is_home_try_on) AS num_try_on, SUM(is_purchase) AS num_purchased, 1.0 * SUM(is_purchase) / SUM(is_home_try_on) AS purchase_rate, ROUND(AVG(price),2) AS avg_price
FROM funnels
GROUP BY fit
ORDER BY purchase_rate DESC;

--Extras: Similar to above query, but selecting the shape column
WITH funnels AS (SELECT q.user_id, h.user_id IS NOT NULL AS 'is_home_try_on', h.number_of_pairs, p.user_id IS NOT NULL AS 'is_purchase', q.fit, p.price, q.shape
FROM quiz AS 'q'
LEFT JOIN home_try_on AS 'h'
	ON q.user_id = h.user_id
LEFT JOIN purchase AS 'p'
	ON p.user_id = q.user_id)
  
SELECT shape, SUM(is_home_try_on) AS num_try_on, SUM(is_purchase) AS num_purchased, 1.0 * SUM(is_purchase) / SUM(is_home_try_on) AS purchase_rate, ROUND(AVG(price),2) AS avg_price
FROM funnels
GROUP BY shape
ORDER BY purchase_rate DESC;

