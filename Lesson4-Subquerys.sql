### First SUBQUERY
/*
 1. We want to find the average number of events for each day for each channel. The first table will provide us the
   number of events for each day and channel, and then we will need to average these values together using a second
   query.
*/
SELECT channel, AVG(events_per_day) avg_events_day
FROM (SELECT DATE_TRUNC('day', occurred_at) "event day",
		         channel,
             COUNT(*) events_per_day
      FROM web_events
      GROUP BY 1, 2) AS subq
GROUP BY channel
ORDER BY 2 DESC;


### More on subquerys
/*
 1. Pull the first or minimum month/year combo from the orders table.
*/
SELECT DATE_TRUNC('month', MIN(occurred_at)) min_month,
FROM orders;
/*
 2. Pull the average for each, and the total usd selled that month (in second query)
*/
SELECT AVG(standard_qty) avg_standard,
       AVG(gloss_qty) avg_gloss,
       AVG(poster_qty) avg_poster
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) AS min_month
	     FROM orders);

SELECT SUM(total_amt_usd) AS total_minmonth_selled
FROM orders
WHERE DATE_TRUNC('month', occurred_at) =
      (SELECT DATE_TRUNC('month', MIN(occurred_at)) AS min_month
	     FROM orders);


### Subquery Mania
/*
 1. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.
*/
First, I wanted to find the total_amt_usd totals associated with each sales rep, and I also wanted the region in
which they were located. The query below provided this information:

SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
FROM region r
JOIN sales_reps s
ON s.region_id = r.id
JOIN accounts a
ON a.sales_rep_id = s.id
JOIN orders o
ON o.account_id = a.id
GROUP BY 1, 2
ORDER BY 3 DESC;

Next, I pulled the max for each region, and then we can use this to pull those rows in our final result:

SELECT region_name, MAX(total_amt) total_amt
FROM (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
      FROM region r
      JOIN sales_reps s
      ON s.region_id = r.id
      JOIN accounts a
      ON a.sales_rep_id = s.id
      JOIN orders o
      ON o.account_id = a.id
      GROUP BY 1, 2) subq1
GROUP BY 1;

Essentially, this is a JOIN of these two tables, where the region and amount match.

SELECT t3.rep_name, t3.region_name, t3.total_amt
FROM(SELECT region_name, MAX(total_amt) total_amt
     FROM(SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
             FROM sales_reps s
             JOIN accounts a
             ON a.sales_rep_id = s.id
             JOIN orders o
             ON o.account_id = a.id
             JOIN region r
             ON r.id = s.region_id
             GROUP BY 1, 2) t1
     GROUP BY 1) t2
JOIN (SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
     FROM sales_reps s
     JOIN accounts a
     ON a.sales_rep_id = s.id
     JOIN orders o
     ON o.account_id = a.id
     JOIN region r
     ON r.id = s.region_id
     GROUP BY 1,2
     ORDER BY 3 DESC) t3
ON t3.region_name = t2.region_name AND t3.total_amt = t2.total_amt;
/*
 2. For the region with the largest sales total_amt_usd, how many total orders were placed?
*/
SELECT r.name, COUNT(o.total) total_orders
FROM region r
JOIN sales_reps sr
ON sr.region_id = r.id
JOIN accounts a
ON sr.id = a.sales_rep_id
JOIN orders o
ON o.account_id = a.id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (
	     SELECT MAX(total_amt_selled) max_selled
       FROM (SELECT r.name, SUM(total_amt_usd) total_amt_selled
             FROM region r
             JOIN sales_reps sr
             ON sr.region_id = r.id
             JOIN accounts a
             ON sr.id = a.sales_rep_id
             JOIN orders o
             ON o.account_id = a.id
             GROUP BY r.name) subq);
/*
 3. How many accounts had more total purchases than the account name which has bought the most standard_qty paper
   throughout their lifetime as a customer?
*/
SELECT COUNT(*)
FROM (SELECT a.name
      FROM orders o
      JOIN accounts a
      ON a.id = o.account_id
      GROUP BY 1
      HAVING SUM(o.total) >
          (SELECT total
           FROM (SELECT a.name, SUM(o.standard_qty) total_std, SUM(o.total) total
                FROM accounts a
                JOIN orders o
                ON o.account_id = a.id
                GROUP BY 1
                ORDER BY 2 DESC
                LIMIT 1) inner_subq)
	       ) counter_subq;

3 accounts is the answer.
/*
 4. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many
   web_events did they have for each channel?
 */
SELECT a.name, w.channel, COUNT(*) total_web_events
FROM accounts a
JOIN web_events w
ON w.account_id = a.id
  AND a.id = (SELECT id
              FROM (SELECT a.id, a.name, MAX(o.total_amt_usd) total_max
                    FROM accounts a
                    JOIN orders o
                    ON o.account_id = a.id
                    GROUP BY 1, 2
                    ORDER BY 3 DESC
                    LIMIT 1) subq)
GROUP BY 1, 2
ORDER BY 3 DESC;
/*
 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?
*/
SELECT AVG(max_totals_spent)
FROM (SELECT a.id, a.name, SUM(o.total_amt_usd) max_totals_spent
      FROM accounts a
      JOIN orders o
      ON o.account_id = a.id
      GROUP BY 1, 2
      ORDER BY 3 DESC
      LIMIT 10) subq;
/*
 6. What is the lifetime average amount spent in terms of total_amt_usd, including only the companies that spent
   more per order, on average, than the average of all orders.
*/
SELECT AVG(avg_amt)
FROM (SELECT o.account_id, AVG(o.total_amt_usd) avg_amt
      FROM orders o
      GROUP BY 1
      HAVING AVG(o.total_amt_usd) > (SELECT AVG(o.total_amt_usd) avg_all
                                     FROM orders o)) subq;


### WITH -> forma un poco más limpia de escribir las subquerys
/*
 1. Provide the name of the sales_rep in each region with the largest amount of total_amt_usd sales.
*/
WITH t1 AS(
       SELECT s.name rep_name, r.name region_name, SUM(o.total_amt_usd) total_amt
       FROM sales_reps s
       JOIN accounts a
       ON a.sales_rep_id = s.id
       JOIN orders o
       ON o.account_id = a.id
       JOIN region r
       ON r.id = s.region_id
       GROUP BY 1,2
       ORDER BY 3 DESC),
 t2 AS(
       SELECT region_name, MAX(total_amt) total_amt
       FROM t1
       GROUP BY 1)

SELECT t1.rep_name, t1.region_name, t1.total_amt
FROM t1
JOIN t2
ON t1.region_name = t2.region_name AND t1.total_amt = t2.total_amt;
/*
 2. For the region with the largest sales total_amt_usd, how many total orders were placed?
*/
WITH t1 AS (
       SELECT r.name reg_name, SUM(total_amt_usd) total_amt_selled
        FROM region r
        JOIN sales_reps sr
        ON sr.region_id = r.id
        JOIN accounts a
        ON sr.id = a.sales_rep_id
        JOIN orders o
        ON o.account_id = a.id
        GROUP BY r.name),
     t2 AS (
       SELECT MAX(total_amt_selled) max_selled
       FROM t1)

SELECT r.name, COUNT(o.total) total_orders
FROM region r
JOIN sales_reps sr
ON sr.region_id = r.id
JOIN accounts a
ON sr.id = a.sales_rep_id
JOIN orders o
ON o.account_id = a.id
GROUP BY r.name
HAVING SUM(o.total_amt_usd) = (SELECT * FROM t2);
/*
 3.How many accounts had more total purchases than the account name which has bought the most standard_qty paper
   throughout their lifetime as a customer?
*/
WITH t1 AS (
      SELECT a.name ac_name, SUM(o.standard_qty) total_std, SUM(o.total) total
       FROM accounts a
       JOIN orders o
       ON o.account_id = a.id
       GROUP BY 1
       ORDER BY 2 DESC
       LIMIT 1),
    t2 AS (
     SELECT a.name
      FROM orders o
      JOIN accounts a
      ON a.id = o.account_id
      GROUP BY 1
      HAVING SUM (o.total) > (SELECT total FROM t1))

SELECT COUNT(*)
FROM t2;
/*
 4. For the customer that spent the most (in total over their lifetime as a customer) total_amt_usd, how many
   web_events did they have for each channel?
*/
WITH t1 AS (
      SELECT a.id, a.name ac_name, MAX(o.total_amt_usd) total_max
        FROM accounts a
        JOIN orders o
        ON o.account_id = a.id
        GROUP BY 1, 2
        ORDER BY 3 DESC
        LIMIT 1)

SELECT a.name, w.channel, COUNT(*) total_web_events
FROM accounts a
JOIN web_events w
ON a.id = w.account_id AND a.id = (SELECT id FROM t1)
GROUP BY 1, 2
ORDER BY 3 DESC;
/*
 5. What is the lifetime average amount spent in terms of total_amt_usd for the top 10 total spending accounts?
*/
WITH t1 AS (
       SELECT a.id, a.name ac_name, SUM(o.total_amt_usd) max_totals_spent
        FROM accounts a
        JOIN orders o
        ON o.account_id = a.id
        GROUP BY 1, 2
        ORDER BY 3 DESC
        LIMIT 10)

SELECT ac_name, AVG(max_totals_spent) avg_spent
FROM t1
GROUP BY 1
ORDER BY 2 DESC;
/*
 6. What is the lifetime average amount spent in terms of total_amt_usd, including only the companies that spent
   more per order, on average, than the average of all orders.What is the lifetime average amount spent in terms of
   total_amt_usd, including only the companies that spent more per order, on average, than the average of all orders.
*/
WITH t1 AS (
          SELECT AVG(o.total_amt_usd) avg_all
           FROM orders o),
     t2 AS (
          SELECT o.account_id, AVG(o.total_amt_usd) avg_amt
           FROM orders o
           GROUP BY 1
           HAVING AVG(o.total_amt_usd) > (SELECT * FROM t1))

SELECT AVG(avg_amt)
FROM t2;
