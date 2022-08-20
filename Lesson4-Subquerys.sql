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
