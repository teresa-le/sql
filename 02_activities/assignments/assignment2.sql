/* ASSIGNMENT 2 */
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a 
blank for the first problem, and 'unit' for the second problem. 

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT 
COALESCE(product_name, ' ') || ', ' || COALESCE(product_size, ' ') || ' (' || COALESCE(product_qty_type, 'unit') || ')'
FROM product


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT DISTINCT 
    market_date, 
    customer_id, 
    DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number
FROM customer_purchases;


/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT MAX(market_date), 
	   customer_id,
	   visit_number 
FROM 
	(SELECT DISTINCT 
		market_date, 
		customer_id, 
		DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date) AS visit_number
	FROM customer_purchases)
GROUP BY customer_id

/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

SELECT DISTINCT 
	   customer_id, 
       product_id, 
       COUNT(product_id) OVER (PARTITION BY customer_id, product_id) AS times_purchased 
FROM customer_purchases 


-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name, 
	   SUBSTR(product_name,NULLIF(INSTR(product_name, '-'), 0) +1) AS description
FROM product;

/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT product_name, 
	   SUBSTR(product_name,NULLIF(INSTR(product_name, '-'), 0) +1) AS description
FROM product
WHERE product_size REGEXP '[0-9]';

-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

WITH market_date_sales AS 
	(SELECT market_date,
		   SUM(cost_to_customer_per_qty * quantity) as sales 
	FROM customer_purchases 
	GROUP BY market_date
	ORDER BY sales)
	
SELECT max(sales),
	   market_date
FROM market_date_sales
UNION  
SELECT min(sales),
	   market_date
FROM market_date_sales

/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */

SELECT *
FROM (
    SELECT DISTINCT customer_id, customer_first_name, customer_last_name
    FROM customer
) AS customer_subquery
CROSS JOIN (
    SELECT DISTINCT vendor_name, product_name
    FROM vendor_inventory vi
    INNER JOIN vendor v ON vi.vendor_id = v.vendor_id
    INNER JOIN product p ON p.product_id = vi.product_id
) AS product_vendor_subquery;

-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

CREATE TABLE product_units AS 
	SELECT *, 
	       CURRENT_TIMESTAMP as snapshot_timestamp
	FROM product
	WHERE product_qty_type = "unit";
	
	
SELECT * FROM product_units;


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units 
VALUES (8, 'Cherry Pie', '10"', 3, 'unit', CURRENT_TIMESTAMP);

SELECT * FROM product_units;


-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/


DELETE FROM product_units
WHERE product_name = 'Cherry Pie'
  AND snapshot_timestamp < (
      SELECT MAX(snapshot_timestamp)
      FROM product_units
      WHERE product_name = 'Cherry Pie'
  );

SELECT * FROM product_units;

-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */


ALTER TABLE product_units
ADD current_quantity INT;

SELECT 
    v.product_id,
    SUM(v.product_quantity) OVER (PARTITION BY v.market_date ORDER BY v.market_date) AS running_total
FROM product_units p
INNER JOIN vendor_inventory v 
    ON p.product_category_id = v.product_id;

