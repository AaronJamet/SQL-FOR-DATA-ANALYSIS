### FULL OUTER JOIN
/*
 Sintaxis
*/
SELECT column_name(s)
FROM Table_A
FULL OUTER JOIN Table_B
ON Table_A.column_name = Table_B.column_name;

A common application of this is when joining two tables on a timestamp. Let’s say you’ve got one table containing
the number of item 1 sold each day, and another containing the number of item 2 sold. If a certain date, like
January 1, 2018, exists in the left table but not the right, while another date, like January 2, 2018, exists in
the right table but not the left:

 - a left join would drop the row with January 2, 2018 from the result set
 - a right join would drop January 1, 2018 from the result set

The only way to make sure both January 1, 2018 and January 2, 2018 make it into the results is to do a full outer join.
A full outer join returns unmatched records in each table with null values for the columns that came from the opposite
table.

If you wanted to return unmatched rows only, which is useful for some cases of data assessment, you can isolate them
by adding the following line to the end of the query:

WHERE Table_A.column_name IS NULL OR Table_B.column_name IS NULL;

/*
 1. Say you're an analyst at Parch & Posey and you want to see:
    - each account who has a sales rep and each sales rep that has an account (all of the columns in these returned rows
      will be full)
    - but also each account that does not have a sales rep and each sales rep that does not have an account (some of the
      columns in these returned rows will be empty)
*/
SELECT *
FROM accounts a
FULL OUTER JOIN sales_reps s
ON a.sales_rep_id = s.id;

No unmatched rows are returned, which means that each account has at least one sales rep and each sales rep has
at least one account.


### JOINs with comparison operators
/*
 1. Write a query that left joins the accounts table and the sales_reps tables on each sale rep's ID number and joins
  it using the < comparison operator on accounts.primary_poc and sales_reps.name, like so:

   accounts.primary_poc < sales_reps.name

  The query results should be a table with three columns: the account name (e.g. Johnson Controls), the primary contact
  name (e.g. Cammy Sosnowski), and the sales representative's name (e.g. Samuel Racine).
*/
SELECT a.name company_name, a.primary_poc, s.name sales_rep_name
FROM accounts a
LEFT JOIN sales_reps s
ON a.sales_rep_id = s.id
AND a.primary_poc < s.name;

The primary point of contact's full name comes before the sales representative's name alphabetically in the result.


### SELF JOIN
/*
 1. One of the most common use cases for self JOINs is in cases where two events occurred, one after another.

 Modify the query from the previous video, which is pre-populated in the SQL Explorer below, to perform the same
 interval analysis except for the web_events table. Also:

 - change the interval to 1 day to find those web events that occurred after, but not more than 1 day after, another web event
 - add a column for the channel variable in both instances of the table in your query
*/
SELECT w1.id AS w1_id,
       w1.account_id AS w1_account_id,
       w1.occurred_at AS w1_occurred_at,
       w1.channel AS w1_channel,
       w2.id AS w2_id,
       w2.account_id AS w2_account_id,
       w2.occurred_at AS w2_occurred_at,
       w2.channel AS w2_channel
FROM web_events w1
LEFT JOIN web_events w2
ON w1.account_id = w2.account_id
AND w2.occurred_at > w1.occurred_at
AND w2.occurred_at <= w1.occurred_at + INTERVAL '1 days'
ORDER BY w1.account_id, w2.occurred_at;


### UNION
/*
 1. Write a query that uses UNION ALL on two instances (and selecting all columns) of the accounts table. Then inspect
  the results and answer the subsequent quiz.
*/
SELECT *
FROM accounts

UNION ALL

SELECT *
FROM accounts;

UNION only appends distinct values. More specifically, when you use UNION, the dataset is appended, and any rows in
the appended table that are exactly identical to rows in the first table are dropped. If you’d like to append all
the values from the second table, use UNION ALL. You’ll likely use UNION ALL far more often than UNION.
/*
 2. Add a WHERE clause to each of the tables that you unioned in the query above, filtering the first table where
  name equals Walmart and filtering the second table where name equals Disney. Inspect the results then answer the
  subsequent quiz.
*/
SELECT *
FROM accounts
WHERE name = 'Walmart'

UNION ALL

SELECT *
FROM accounts
WHERE name = 'Disney';

- How else could the above query results be generated?:
    SELECT *
    FROM accounts
    WHERE name = 'Walmart' OR name = 'Disney';


/*
 3. Perform the union in your first query (under the Appending Data via UNION header) in a common table expression
  and name it double_accounts. Then do a COUNT the number of times a name appears in the double_accounts table. If
  you do this correctly, your query results should have a count of 2 for each name.
*/
WITH double_accounts AS (SELECT *
    FROM accounts

    UNION ALL

    SELECT *
    FROM accounts)

SELECT name,
       COUNT(*) AS times_appearing
FROM double_accounts
GROUP BY 1
ORDER BY 2 DESC;
