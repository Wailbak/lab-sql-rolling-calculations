USE sakila;

-- Listing each pair of actors that have worked together.
SELECT 
    fa1.actor_id AS actor_id_1, 
    a1.first_name AS actor_1_first_name, 
    a1.last_name AS actor_1_last_name, 
    fa2.actor_id AS actor_id_2,
    a2.first_name AS actor_2_first_name, 
    a2.last_name AS actor_2_last_name,
    f.title AS film_title
FROM 
    film_actor fa1
JOIN 
    film_actor fa2 ON fa1.film_id = fa2.film_id AND fa1.actor_id < fa2.actor_id
JOIN 
    actor a1 ON fa1.actor_id = a1.actor_id
JOIN 
    actor a2 ON fa2.actor_id = a2.actor_id
JOIN 
    film f ON fa1.film_id = f.film_id
ORDER BY 
    fa1.actor_id, fa2.actor_id;
----------------------------------------------------------------------------------------------------------------------------------------------------

-- Finding the actor who has acted in the most films for each film
WITH ActorFilmCounts AS (
    SELECT 
        fa.actor_id, 
        COUNT(*) AS total_films
    FROM 
        film_actor fa
    GROUP BY 
        fa.actor_id
),
FilmActorRanks AS (
    SELECT 
        f.film_id,
        f.title AS film_title,
        a.actor_id,
        a.first_name,
        a.last_name,
        afc.total_films,
        RANK() OVER(PARTITION BY f.film_id ORDER BY afc.total_films DESC) AS ranking
    FROM 
        film f
    JOIN 
        film_actor fa ON f.film_id = fa.film_id
    JOIN 
        actor a ON fa.actor_id = a.actor_id
    JOIN 
        ActorFilmCounts afc ON a.actor_id = afc.actor_id
)
SELECT 
    film_id,
    film_title,
    actor_id,
    first_name,
    last_name,
    total_films
FROM 
    FilmActorRanks
WHERE 
    ranking = 1;
--------------------------------------------------------------------------------------------------------------------------------------------

--  Obtaining the number of monthly active customers.
SELECT 
    YEAR(rental_date) AS Year, 
    MONTH(rental_date) AS Month, 
    COUNT(DISTINCT customer_id) AS Monthly_Active_Customers
FROM 
    rental
GROUP BY 
    YEAR(rental_date), MONTH(rental_date)
ORDER BY 
    Year, Month;
------------------------------------------------------------------------------------------------------------------------------------------------

-- Extracting active users in the previous month.
WITH MonthlyActive AS (
    SELECT 
        YEAR(rental_date) AS year, 
        MONTH(rental_date) AS month, 
        COUNT(DISTINCT customer_id) AS active_customers
    FROM 
        rental
    GROUP BY 
        year, month
    ORDER BY 
        year, month
)

SELECT 
    year, 
    month, 
    active_customers,
    LAG(active_customers) OVER (ORDER BY year, month) AS previous_month_customers,
    round(((active_customers - LAG(active_customers) OVER (ORDER BY year, month)) / LAG(active_customers) OVER (ORDER BY year, month)) * 100,1) AS pct_change
FROM 
    MonthlyActive;
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Retrieving the number of retained customers every month.
WITH MonthlyCustomers AS (
    SELECT
        customer_id,
        YEAR(rental_date) AS year,
        MONTH(rental_date) AS month
    FROM 
        rental
    GROUP BY 
        customer_id, year, month
),
CustomerActivity AS (
    SELECT
        customer_id,
        year,
        month,
        LEAD(year) OVER(PARTITION BY customer_id ORDER BY year, month) AS next_year,
        LEAD(month) OVER(PARTITION BY customer_id ORDER BY year, month) AS next_month
    FROM 
        MonthlyCustomers
)
SELECT
    year,
    month,
    COUNT(customer_id) AS Retained_Customers
FROM 
    CustomerActivity
WHERE 
    (next_year = year AND next_month = month + 1) 
    OR (next_year = year + 1 AND month = 12 AND next_month = 1)
GROUP BY 
    year, month
ORDER BY 
    year, month;













