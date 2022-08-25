### LEFT, RIGHT & LENGTH
/*
 First example
*/
SELECT first_name, last_name, phone_number
       LEFT(phone_number, 3),
       RIGHT(phone_number, 8),
       RIGHT(phone_number, LENGTH(phone_number - 4)) AS phone_number_alt
FROM customer_data
/*
 1. In the accounts table, there is a column holding the website for each company. The last three digits specify what
   type of web address they are using. A list of extensions (and pricing) is provided here. Pull these extensions and
   provide how many of each website type exist in the accounts table.
*/
SELECT RIGHT(website, 4) web_ext, COUNT(*) ext_times_used
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;
/*
 2. There is much debate about how much the name (or even the first letter of a company name) matters. Use the accounts
   table to pull the first letter of each company name to see the distribution of company names that begin with each
   letter (or number).
*/
SELECT LEFT(UPPER(name), 1) first_letter, COUNT(*) num_companies
FROM accounts
GROUP BY 1
ORDER BY 2 DESC;
/*
 3. Use the accounts table and a CASE statement to create two groups: one group of company names that start with a
   number and a second group of those company names that start with a letter. What proportion of company names start
   with a letter?
*/
SELECT SUM(num) nums, SUM(letter) letters
FROM (SELECT name,
             CASE WHEN LEFT(UPPER(name), 1) IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
                  THEN 1 ELSE 0 END as num,
             CASE WHEN LEFT(UPPER(name), 1) IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
                  THEN 0 ELSE 1 END as letter
      FROM accounts) t1;

There are 350 company names that start with a letter and 1 that starts with a number. This gives a ratio of 350/351
that are company names that start with a letter or 99.7%.
/*
 4. Consider vowels as a, e, i, o, and u. What proportion of company names start with a vowel, and what percent start
   with anything else?
*/
SELECT SUM(vowel) vowels, SUM(other_char) other_chars
FROM (SELECT name,
             CASE WHEN LEFT(UPPER(name), 1) IN ('A', 'E', 'I', 'O', 'U')
                  THEN 1 ELSE 0 END as vowel,
             CASE WHEN LEFT(UPPER(name), 1) IN ('A', 'E', 'I', 'O', 'U')
                  THEN 0 ELSE 1 END as other_char
      FROM accounts) t1;

There are 80 company names that start with a vowel and 271 that start with other characters. Therefore 80/351 are vowels
or 22.8%. Therefore, 77.2% of company names do not start with vowels.


### POSITION, STRPOS & SUBSTR
/*
 First example
*/
SELECT first_name, last_name, city_state,
       POSITION(',' IN city_state) AS comma_position,
       STRPOS(city_state, ',') AS substr_comma_position,
       LOWER(city_state) AS lowercase,
       UPPER(city_state) AS uppercase,
       LEFT(city_state, POSITION(',' IN city_state) - 1) AS city_state
FROM customer_data;
/*
 1. Use the accounts table to create first and last name columns that hold the first and last names for the primary_poc.
*/
SELECT LEFT(primary_poc, STRPOS(primary_poc, ' ') - 1) AS first_name,
       RIGHT(primary_poc, LENGTH(primary_poc) -STRPOS(primary_poc, ' ')) AS last_name
FROM accounts;
/*
 2. Now see if you can do the same thing for every rep name in the sales_reps table. Again provide first and last name
   columns.
*/
SELECT LEFT(name, STRPOS(name, ' ') - 1) AS first_name,
       RIGHT(name, LENGTH(name) -STRPOS(name, ' ')) AS last_name
FROM sales_reps;


### CONCAT & ||
/*
 First example
*/
SELECT first_name, last_name,
       CONCAT(first_name, ' ', last_name) AS full_name,
       first_name || ' ' || last_name AS full_name_alt
FROM customer_data
/*
 1. Each company in the accounts table wants to create an email address for each primary_poc. The email address should
   be the first name of the primary_poc . last name primary_poc @ company name .com
*/
WITH t1 AS (
  SELECT name,
         LEFT(primary_poc, STRPOS(primary_poc, ' ') - 1) AS first_name,
         RIGHT(primary_poc, LENGTH(primary_poc) - (STRPOS(primary_poc, ' ')) AS last_name
  FROM accounts
)

SELECT first_name, last_name,
       CONCAT(first_name, '.', last_name, '@', name, '.com')
FROM t1;
/*
 2. You may have noticed that in the previous solution some of the company names include spaces, which will certainly
   not work in an email address. See if you can create an email address that will work by removing all of the spaces
   in the account name, but otherwise your solution should be just as in question 1.
*/
WITH t1 AS (
  SELECT name,
         LEFT(primary_poc, STRPOS(primary_poc, ' ') - 1) AS first_name,
         RIGHT(primary_poc, LENGTH(primary_poc) - (STRPOS(primary_poc, ' '))) AS last_name
  FROM accounts
)

SELECT first_name, last_name,
       CONCAT(first_name, '.', last_name, '@', REPLACE(name, ' ', ''), '.com') AS email
FROM t1;
/*
 3. We would also like to create an initial password, which they will change after their first log in. The first
   password will be the first letter of the primary_poc's first name (lowercase), then the last letter of their first
   name (lowercase), the first letter of their last name (lowercase), the last letter of their last name (lowercase),
   the number of letters in their first name, the number of letters in their last name, and then the name of the
   company they are working with, all capitalized with no spaces.
*/
WITH t1 AS (
          SELECT name,
                 LEFT(primary_poc, STRPOS(primary_poc, ' ') - 1) AS first_name,
                 RIGHT(primary_poc, LENGTH(primary_poc) - (STRPOS(primary_poc, ' '))) AS last_name
          FROM accounts)

SELECT first_name, last_name,
       CONCAT(first_name, '.', last_name, '@', name, '.com') AS email,
       LEFT(LOWER(first_name), 1) || RIGHT(LOWER(first_name), 1) || LEFT(LOWER(last_name), 1) ||
          RIGHT(LOWER(last_name), 1) || LENGTH(first_name) || LENGTH(last_name) || REPLACE(UPPER(name), ' ', '') AS password
FROM t1;


### CAST
/*
 1. Format the date column as yyyy-mm-dd
*/
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2)) new_date
FROM sf_crime_data;
/*
 2. This new date can be operated on using DATE_TRUNC and DATE_PART
*/
SELECT date orig_date, (SUBSTR(date, 7, 4) || '-' || LEFT(date, 2) || '-' || SUBSTR(date, 4, 2))::DATE new_date
FROM sf_crime_data;


### COALESCE
/*
 Example
*/
SELECT COUNT(primary_poc) AS regular_count,
       COUNT(COALESCE(primary_poc, 'no POC')) AS count_with_nulls_included
FROM accounts
