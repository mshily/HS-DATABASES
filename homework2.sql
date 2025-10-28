-- List countries. whose population is greater than the average population of all countries.
SELECT co.Name, co.Population
FROM country AS co
WHERE co.Population > (SELECT AVG(c.Population) FROM country AS c);

-- Find cities whose population is larger than their country’s average city population.
SELECT c.Name, c.CountryCode, c.Population
FROM city AS c
WHERE c.Population > (SELECT AVG(c1.Population) FROM city AS c1 WHERE c1.CountryCode = c.CountryCode);

-- “Tiny but Mighty” Countries. Find the countries that have a smaller population than the city of Tokyo, but a larger life expectancy than the average life expectancy of all countries.
SELECT co.Name, co.Population, co.LifeExpectancy
FROM country AS co
WHERE co.Population < (SELECT tokyo.Population FROM city AS tokyo WHERE tokyo.Name = 'Tokyo' LIMIT 1) AND
co.LifeExpectancy > (SELECT AVG(c.LifeExpectancy) FROM country AS c);


-- IN

-- Countries speaking French, Spanish, or Portuguese
SELECT co.Name
FROM country AS co
JOIN countrylanguage AS cl ON cl.CountryCode = co.Code
WHERE cl.Language IN ('French', 'Spanish', 'Portuguese')
GROUP BY co.Name;

-- Cities in top-10 GNP countries
SELECT ci.Name, ci.CountryCode
FROM city AS ci 
WHERE ci.CountryCode IN (SELECT sub.Code FROM (SELECT co.Code FROM country AS co ORDER BY co.GNP DESC LIMIT 10) AS sub); 

-- Find all countries that claim to speak Spanish, but are not in South America.
SELECT co.Name, co.Continent 
FROM country AS co
WHERE co.Code IN (SELECT cl.CountryCode FROM countrylanguage AS cl WHERE (Language = 'Spanish')) AND co.Continent != 'South America';

UNION

-- Asian and African countries combined
SELECT co.Name FROM country AS co WHERE co.Continent = 'Asia'
UNION 
SELECT co.Name FROM country AS co WHERE co.Continent = 'African';

-- List the names of the richest countries (GNP > 500000) together with the largest cities (population > 8,000,000) — all in one column PlaceName.
SELECT co.Name AS PlaceName FROM country AS co
WHERE co.GNP > 500000
UNION 
SELECT ci.Name FROM city AS ci 
WHERE ci.Population > 8000000;


-- CTE
-- Find the top 3 most populous countries in each continent (use PARTITION BY)
WITH top_country AS (
    SELECT co.Name AS Name, co.Population As Population, co.Continent AS Continent,
    RANK() OVER (PARTITION BY co.Continent ORDER BY co.Population DESC) AS rn
    FROM country AS co     
)
SELECT Name, Population, Continent, rn
FROM top_country
WHERE rn <= 3;

-- Find countries that became independent before the average independence year of all countries.
WITH avg AS (
    SELECT AVG(IndepYear) AS avg FROM country 
)
SELECT co.Name, co.IndepYear, avg.avg
FROM country AS CO
JOIN avg
WHERE co.IndepYear < avg.avg;

-- Recursive
-- CTE to generate numbers 1–10
WITH RECURSIVE rec(n) AS (
    SELECT 1
    UNION ALL 
    SELECT n + 1 FROM rec WHERE n < 10
)
SELECT * FROM rec;