-- When was the first payment done? When the last?
SELECT pa.payment_id, payment_date FROM payment AS pa ORDER BY payment_date LIMIT 1;
SELECT pa.payment_id, payment_date FROM payment AS pa ORDER BY payment_date DESC LIMIT 1;

-- another way (i am just practicing:) )
SELECT MIN(payment_date), MAX(payment_date) FROM payment;

-- Report total payments by year. By month.
SELECT YEAR(payment_date) AS Y, MONTH(payment_date) AS M, SUM(amount)
FROM payment
GROUP BY Y, M
ORDER BY Y, M; 

-- Which film brings more money to the company? Which actor?
-- for amount of money I need film -> inventory -> rental -> payment
SELECT f.title, SUM(p.amount) as SUM
FROM film AS f
JOIN inventory AS i ON f.film_id = i.film_id
JOIN rental AS r ON r.inventory_id = i.inventory_id
JOIN payment AS p ON p.rental_id = r.rental_id
GROUP BY f.title
ORDER BY SUM DESC
LIMIT 1;

-- Now go to the actor
WITH fb AS (
    SELECT f.film_id AS film_id, f.title, SUM(p.amount) AS total_sum
    FROM film AS f
    JOIN inventory AS i ON f.film_id = i.film_id
    JOIN rental AS r ON r.inventory_id = i.inventory_id
    JOIN payment AS p ON p.rental_id = r.rental_id
    GROUP BY f.film_id, f.title
)
SELECT a.first_name, a.last_name, SUM(fb.total_sum) AS sum
FROM film_actor AS fa
JOIN actor AS a ON a.actor_id = fa.actor_id
JOIN fb ON fb.film_id = fa.film_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY sum DESC
LIMIT 1;

-- Customers from which city pays more money?
WITH topc AS (
    SELECT ct.city_id, ct.city, SUM(pm.amount) AS SUM
    FROM customer AS cs
    JOIN address AS ad ON ad.address_id = cs.address_id
    JOIN city AS ct ON ct.city_id = ad.city_id
    JOIN payment AS pm ON pm.customer_id = cs.customer_id
    GROUP BY ct.city_id, ct.city
    ORDER BY SUM DESC
)
SELECT t.city, t.SUM 
FROM (
    SELECT tc.*, RANK() OVER (ORDER BY tc.SUM DESC) AS rnk 
    FROM topc AS tc
) AS t
WHERE rnk = 1;


-- Create list of the films that was leaders by month.
-- Actually i dont know leaders by what. I think there are two situations:
-- 1) leader by income
-- 2) leader by number of rental
-- Obviously the second one more difficult. I will make it. 

WITH monthly AS (
    SELECT f.film_id AS id, f.title AS title, SUM(p.amount) AS total, YEAR(p.payment_date) AS Y, MONTH(p.payment_date) AS M
    FROM film AS f
    JOIN inventory AS i ON f.film_id = i.film_id
    JOIN rental AS r ON r.inventory_id = i.inventory_id
    JOIN payment AS p ON p.rental_id = r.rental_id
    GROUP BY Y, M, f.film_id, f.title
    ORDER BY total
)
SELECT m.rnk, m.title, m.Y, m.M, m.total
FROM (
    SELECT m.*,
        RANK() OVER (PARTITION BY m.Y, m.M ORDER BY m.total DESC) AS rnk
    FROM monthly AS m
) AS m
WHERE m.rnk = 1
GROUP BY m.id, m.title, m.Y, m.M;


-- Combine data from last_update fields from all the tables.
SELECT 'actor' AS table_name, last_update FROM actor
UNION ALL
SELECT 'address',  last_update FROM address
UNION ALL
SELECT 'category', last_update FROM category
UNION ALL
SELECT 'city',     last_update FROM city
UNION ALL
SELECT 'country',  last_update FROM country
UNION ALL
SELECT 'customer', last_update FROM customer
UNION ALL
SELECT 'film',     last_update FROM film
UNION ALL
SELECT 'film_actor',     last_update FROM film_actor
UNION ALL
SELECT 'film_category',  last_update FROM film_category
UNION ALL
SELECT 'inventory', last_update FROM inventory
UNION ALL
SELECT 'language',  last_update FROM language
UNION ALL
SELECT 'payment',   last_update FROM payment
UNION ALL
SELECT 'rental',    last_update FROM rental
UNION ALL
SELECT 'staff',     last_update FROM staff
UNION ALL
SELECT 'store',     last_update FROM store
ORDER BY last_update DESC;

-- But idk maybe you need to the most freshest value:
SELECT 'actor' AS table_name,     MAX(last_update) AS last_update FROM actor
UNION ALL SELECT 'address',       MAX(last_update) FROM address
UNION ALL SELECT 'category',      MAX(last_update) FROM category
UNION ALL SELECT 'city',          MAX(last_update) FROM city
UNION ALL SELECT 'country',       MAX(last_update) FROM country
UNION ALL SELECT 'customer',      MAX(last_update) FROM customer
UNION ALL SELECT 'film',          MAX(last_update) FROM film
UNION ALL SELECT 'film_actor',    MAX(last_update) FROM film_actor
UNION ALL SELECT 'film_category', MAX(last_update) FROM film_category
UNION ALL SELECT 'inventory',     MAX(last_update) FROM inventory
UNION ALL SELECT 'language',      MAX(last_update) FROM language
UNION ALL SELECT 'payment',       MAX(last_update) FROM payment
UNION ALL SELECT 'rental',        MAX(last_update) FROM rental
UNION ALL SELECT 'staff',         MAX(last_update) FROM staff
UNION ALL SELECT 'store',         MAX(last_update) FROM store
ORDER BY last_update DESC;

-- Calculate frequency of update for all the tables.
WITH all_updates AS (
  SELECT 'actor' AS table_name, last_update AS ts FROM actor
  UNION ALL SELECT 'address',  last_update FROM address
  UNION ALL SELECT 'category', last_update FROM category
  UNION ALL SELECT 'city',     last_update FROM city
  UNION ALL SELECT 'country',  last_update FROM country
  UNION ALL SELECT 'customer', last_update FROM customer
  UNION ALL SELECT 'film',     last_update FROM film
  UNION ALL SELECT 'film_actor',     last_update FROM film_actor
  UNION ALL SELECT 'film_category',  last_update FROM film_category
  UNION ALL SELECT 'inventory', last_update FROM inventory
  UNION ALL SELECT 'language',  last_update FROM language
  UNION ALL SELECT 'payment',   last_update FROM payment
  UNION ALL SELECT 'rental',    last_update FROM rental
  UNION ALL SELECT 'staff',     last_update FROM staff
  UNION ALL SELECT 'store',     last_update FROM store
)
SELECT
    table_name,
    DATE(ts) AS day,
    COUNT(*) AS updates_per_day
FROM all_updates
GROUP BY table_name, day
ORDER BY day, table_name;
