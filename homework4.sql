-- Select staff members who sell the winning film.

-- So idk what's 'winning film'. So previosly there was "Which film brings more money to the company?".
-- To impement something new let 'winning film' is about amount of rentals this film.
WITH film_rank AS (
    SELECT
        f.film_id,
        f.title,
        COUNT(*) AS rentals,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM rental AS r
    JOIN inventory AS i ON r.inventory_id = i.inventory_id
    JOIN film AS f ON f.film_id = i.film_id
    GROUP BY f.film_id, f.title
)
SELECT
    s.staff_id,
    CONCAT(s.first_name, ' ', s.last_name) AS staff,
    fr.title AS winning_film,
    COUNT(*) AS sales_handled
FROM film_rank AS fr
JOIN inventory AS i ON i.film_id = fr.film_id
JOIN rental AS r ON r.inventory_id = i.inventory_id
JOIN staff AS s ON s.staff_id = r.staff_id
WHERE fr.rnk = 1
GROUP BY s.staff_id, staff, fr.title
ORDER BY sales_handled DESC, staff;

-- Select staff members who not sell anything at all. In 2006?

-- for all years
SELECT s.staff_id,
       CONCAT(s.first_name, ' ', s.last_name) AS staff
FROM staff AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM payment AS p
    WHERE p.staff_id = s.staff_id
);
-- for 2006
SELECT s.staff_id,
       CONCAT(s.first_name, ' ', s.last_name) AS staff
FROM staff AS s
WHERE NOT EXISTS (
    SELECT 1
    FROM payment AS p
    WHERE p.staff_id = s.staff_id
    AND p.payment_date >= '2006-01-01'
    AND p.payment_date <  '2007-01-01'
);

-- Find a films that never was rented. Not rented in 2006
-- film -> inventory -> rental

-- for all:
SELECT f.title
FROM film AS f
WHERE NOT EXISTS (
    SELECT 1
    FROM rental AS r
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
);

-- in 2006
SELECT f.title
FROM film AS f
WHERE NOT EXISTS (
    SELECT 1
    FROM rental AS r
    JOIN inventory AS i ON i.inventory_id = r.inventory_id
    WHERE i.film_id = f.film_id
    AND r.rental_date >= '2006-01-01'
    AND r.rental_date <  '2007-01-01'
);


-- Find the Longest and Shortest Films
-- ofc i can create to tables. But it is very simple.

WITH ranked AS (
    SELECT film_id, title, length,
        RANK() OVER (ORDER BY length DESC) AS r_max,
        RANK() OVER (ORDER BY length ASC)  AS r_min
    FROM film
)
SELECT CASE WHEN r_max = 1 THEN 'Longest' ELSE 'Shortest' END AS kind,
    film_id, title, length
FROM ranked
WHERE r_max = 1 OR r_min = 1
ORDER BY kind, title;

-- Calculate the Average Payment Amount by Customer
SELECT c.first_name, c.last_name, AVG(p.amount)
FROM customer AS c
JOIN payment AS p ON p.customer_id = c.customer_id
GROUP BY c.customer_id;

-- Find the Total Number of Rentals per Store
SELECT
  s.store_id,
  COUNT(r.rental_id) AS rentals_total
FROM store s
JOIN inventory i ON i.store_id = s.store_id
JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY s.store_id
ORDER BY s.store_id;

-- Find Actors Who Have Worked Together in Multiple Films 

-- In this exersice i think that "Multiple Films" means ">= 2"
SELECT
    LEAST(a1.actor_id, a2.actor_id)  AS actor1_id,
    GREATEST(a1.actor_id, a2.actor_id) AS actor2_id,
    CONCAT(a1.first_name, ' ', a1.last_name) AS actor1,
    CONCAT(a2.first_name, ' ', a2.last_name) AS actor2,
    COUNT(DISTINCT fa1.film_id) AS films_together
FROM film_actor AS fa1
JOIN film_actor AS fa2 ON fa1.film_id = fa2.film_id
AND fa1.actor_id < fa2.actor_id
JOIN actor AS a1 ON a1.actor_id = fa1.actor_id
JOIN actor AS a2 ON a2.actor_id = fa2.actor_id
GROUP BY actor1_id, actor2_id, actor1, actor2
HAVING COUNT(DISTINCT fa1.film_id) >= 2
ORDER BY films_together DESC, actor1, actor2;
