USE sakila;

-- Part 1 – Check Default Optimizer Behavior
-- Reflection: Does MySQL use an index or a full table scan? What might the optimizer be missing?

EXPLAIN FORMAT=JSON
SELECT * FROM sakila.film_actor WHERE actor_id = 1;

EXPLAIN FORMAT=JSON
SELECT * FROM sakila.film_actor WHERE actor_id = 50;

-- Question: Does MySQL use an index or a full table scan?
/* 
It uses an index.  Our EXPLAIN FORMAT=JSON shows that access_type: "ref", key: "PRIMARY", and used_key_parts: ["actor_id"], which means an index lookup on actor_id - not a full table scan.
And it is true for both actor_id = 1 and actor_id = 50
*/
-- Question: What might the optimizer be missing?
/*
I think that’s a histogram. It stores the real frequency of each value.
Without it MySQL uses rough stats and assumes values are evenly spread, so it may guess similar row counts for actor_id = 1 and 50.
With it MySQL gets true per-value frequencies, so estimates are better and bigger queries can choose a better join order/plan.
*/

-- ===============================================================================================


-- Part 2 - View Existing Statistics
-- What does the Cardinality column mean?   

SHOW INDEX FROM sakila.film_actor;

/*
Cardinality is estimated number of distinct values for the leftmost prefix of an index. It’s just an approximation, not an exact count.
For a single-column index cardinality ≈ distinct values in that column.

For a composite index (a, b, c):
the row with Seq_in_index=1 shows distinct a,
Seq_in_index=2 shows distinct pairs (a, b),
Seq_in_index=3 shows distinct triples (a, b, c).

Higher cardinality -> more selective index -> the optimizer is more likely to use it (affects plan choice and join order).
*/

-- Question: How could it affect MySQL’s choice of plan?

/*
It changes MySQL’s selectivity estimates, which drive the execution plan.
High cardinality -> more selective -> more likely to use that index (ref/range) and join that table earlier.
Low cardinality -> less selective -> may skip the index and do a table scan (ALL) or pick a different index.
It also affects which index on a table is chosen and the join order.
If estimates are stale, MySQL can pick a worse plan-refresh with ANALYZE TABLE or use histograms.
*/

-- ===============================================================================================

-- Part 3 – Create a Histogram
-- Question: How many buckets were created? What do the numbers represent?

ANALYZE TABLE sakila.film_actor UPDATE HISTOGRAM ON actor_id WITH 10 BUCKETS;

-- Verify creation:
SELECT JSON_PRETTY(HISTOGRAM)
FROM INFORMATION_SCHEMA.COLUMN_STATISTICS
WHERE SCHEMA_NAME = 'sakila'
    AND TABLE_NAME  = 'film_actor'
    AND COLUMN_NAME = 'actor_id'\G

--  Question: How many buckets were created?
/*
10 were requested. 
We can see the exact count is in the JSON as number-of-buckets-used (it can be <= 10 if there aren’t enough distinct values).
*/

-- Qusetion: What do the numbers represent?
/*
Each bucket entry is [lower, upper, cumulative_frequency, distinct_values_in_range].
Example: [1, 21, 0.09996, 21] -> values 1–21 (inclusive), approx 9.996% of rows in [1, 21], 21 distinct values in that range. 
*/

-- ===============================================================================================

-- Part 4 – Compare Query Plans
-- Re-run your queries:
EXPLAIN FORMAT=JSON 
SELECT * FROM sakila.film_actor 
WHERE actor_id = 1; 

EXPLAIN FORMAT=JSON 
SELECT * FROM sakila.film_actor
WHERE actor_id = 50;

-- Discussion: Why did the plan or cost estimate change? What new knowledge did the optimizer gain?
-- Why did the plan or cost estimate change?

/*
It didn’t change because actor_id = * on the leftmost column of the PRIMARY key is already the cheapest path (ref on PRIMARY). 
The table is small enough, so the histogram didn’t change results.
*/

-- What new knowledge did the optimizer gain?
/*
Per-value frequency data for actor_id (from the histogram buckets). 
Even if this simple equality kept the same plan, those distribution stats can improve cardinality/cost estimates in more complex queries (e.g., joins, IN lists, ranges) and help choose a better join order or index there.
*/

-- ===============================================================================================
-- (Optional) Part 5 – Measure Execution Time
-- Question: Compare runtime before and after histogram creation.

SET profiling = 1; 
SELECT * FROM sakila.film_actor WHERE actor_id = 1; 
SHOW PROFILES; 

ANALYZE TABLE sakila.film_actor
  UPDATE HISTOGRAM ON actor_id WITH 10 BUCKETS;

SET profiling = 1; 
SELECT * FROM sakila.film_actor WHERE actor_id = 1; 
SHOW PROFILES; 
/*
without histogram: 
0.00077800

with:
0.00025700

I executed that query 10 times and above it is average query. 
After creating the histogram, the average runtime dropped from 0.00078s to 0.00026s (approx 3x faster). This is likely due to caching effects the plan didn’t change while the histogram mainly improves estimates for more complex queries.
*/

-- ===============================================================================================
-- Part 6 – Clean Up
ANALYZE TABLE sakila.film_actor DROP HISTOGRAM ON actor_id;

/*
Reflection Questions
1 What kind of statistics does MySQL keep for each table and index?
2 Why are histograms especially helpful for non-uniform distributions?
3 What might happen if statistics become outdated?
4 How could histograms improve query performance in large production systems?

+-------------------+-----------+----------+-----------------------------------------------------+
| Table             | Op        | Msg_type | Msg_text                                            |
+-------------------+-----------+----------+-----------------------------------------------------+
| sakila.film_actor | histogram | status   | Histogram statistics removed for column 'actor_id'. |
+-------------------+-----------+----------+-----------------------------------------------------+
*/

-- Answers
/*
1. What kind of statistics does MySQL keep for each table and index?
Tables: estimated row count, pages/size, modification counters.
Indexes: cardinality per leftmost prefix, index size/type/visibility.
*/

/*
2. Why are histograms especially helpful for non-uniform distributions?
They capture real per-value/range frequencies, instead of assuming uniform spread-so selectivity and cost estimates are much more accurate.
*/

/*
3. What might happen if statistics become outdated?
The optimizer misestimates cardinalities and picks worse plans (wrong index, table scans, bad join order), causing slower queries and more I/O/temp work.
*/

/*
4. How could histograms improve query performance in large production systems?
By giving accurate selectivity, they help choose the right index, better join order, and avoid unnecessary sorts/scans—leading to lower latency and more stable plans, especially for complex joins and range.
*/

-- ===============================================================================================
-- Bonus Challenge
/*
Create a small table with skewed data (e.g. 90% of rows share one value). Run the same
experiment and observe how the histogram corrects optimizer estimates.
*/

DROP TABLE IF EXISTS skew;
CREATE TABLE skew (
  id INT PRIMARY KEY AUTO_INCREMENT,
  val INT NOT NULL,
  meow CHAR(50) NULL
);

SHOW VARIABLES LIKE 'cte_max_recursion_depth';
SET SESSION cte_max_recursion_depth = 100000;

/*
Now let's insert data with help of recursion
let's creeate 9000 rows of value = 0
*/

INSERT INTO skew (`val`)
SELECT 0
FROM (
    WITH RECURSIVE seq AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n+1 FROM seq WHERE n < 90000
    )
    SELECT n FROM seq
) AS s;


/*
Then let's insert 1000 random values from 1 to 10
*/

INSERT INTO skew (`val`)
SELECT 1 + (n % 10)
FROM (
    WITH RECURSIVE seq2 AS (
        SELECT 1 AS n
        UNION ALL
        SELECT n+1 FROM seq2 WHERE n < 10000
    )
    SELECT n FROM seq2
) AS s;

/*
Add an index and refresh stats 
*/
CREATE INDEX ix_v ON skew(val);
ANALYZE TABLE skew;
ALTER TABLE skew ALTER INDEX ix_v INVISIBLE;

/*
Now let's do EXPLAIN
Look at access_type, key, rows_examined_per_scan / rows_produced_per_join, cost_info.
We expect that both use ix_v (type "ref"), and the estimated rows may look similar (near-uniform guess).
*/

EXPLAIN FORMAT=JSON SELECT * FROM skew WHERE val = 0;
EXPLAIN FORMAT=JSON SELECT * FROM skew WHERE val = 7;

/*
That's right! Because WHERE v = * matches on the indexed column, MySQL uses that index (ix_v) with non-unique lookups -> access_type = "ref".
Without a histogram, the optimizer assumes values are uniformly distributed, so it estimates similar row counts for v=0 and v=7.
*/

/*
Build a histogram on v

What you should see:
v = 0: estimated rows jump close to ~9000 (high selectivity = low filtering).
v = 7: estimated rows drop near ~100 (10% of 1000 ≈ 100).
Access type may stay ref for both or MySQL might choose ALL (full scan) for v=0 if it decides scanning is cheaper than many random lookups—that decision becomes possible thanks to the histogram’s per-value frequencies.
*/
ALTER TABLE skew ALTER INDEX ix_v VISIBLE;
ANALYZE TABLE skew UPDATE HISTOGRAM ON val WITH 10 BUCKETS;

EXPLAIN FORMAT=JSON SELECT * FROM skew WHERE val = 0; 
EXPLAIN FORMAT=JSON SELECT * FROM skew WHERE val = 7; 

/*
Histogram did work estimates diverged, but plan stayed ref because index lookups are still cheapest for single-table equality.
*/

/*
That was amazing lab! Thanks!
*/