-- SOURCE ~/DATABASES/script1.sql

USE world;

-- Find the capital city of Spain.
SELECT city.Name AS capital_city
FROM country
JOIN city ON country.Capital = city.ID
WHERE country.Name = 'Spain';

-- Which country has the most cities in the database?
SELECT  country.Name AS country_name,
        COUNT(*) AS city_count
FROM city 
JOIN country ON country.Code = city.CountryCode
GROUP BY city.CountryCode
ORDER BY city_count DESC
LIMIT 1;

-- Find the smallest country (by surface area) that has a population of over 10 million.
SELECT country.Name AS counrty_name,
        country.SurfaceArea AS surface_area
FROM country
WHERE country.Population > 10000000
ORDER BY surface_area 
LIMIT 1;

-- List all countries where Spanish is an official language.
SELECT country.Name AS country_name
FROM countrylanguage AS cl
JOIN country ON country.Code = cl.CountryCode
WHERE cl.Language = "Spanish" AND cl.IsOfficial = 'T';

-- Find countries where no official language is recorded in the database.
SELECT cn.Name AS country_name,
        COUNT(cl.language) AS count
FROM country AS cn
LEFT JOIN countrylanguage AS cl ON cn.Code = cl.CountryCode AND cl.IsOfficial = 'T'
GROUP BY cn.Code
HAVING count = 0
ORDER BY count;

-- Which continent has the largest total population?
SELECT  co.Continent AS conitnent, 
        SUM(co.Population) AS sum
FROM country AS co
GROUP BY continent
ORDER BY sum DESC
LIMIT 1;