CREATE DATABASE ay_dannys_dinner;
USE ay_dannys_dinner;

CREATE TABLE dannys_sales(
customer_id VARCHAR(1),
order_date DATE,
product_id INTEGER
);

INSERT INTO dannys_sales 
VALUES
	('A', '2021-01-01', '1'),
	('A', '2021-01-01', '2'),
	('A', '2021-01-07', '2'),
	('A', '2021-01-10', '3'),
	('A', '2021-01-11', '3'),
	('A', '2021-01-11', '3'),
	('B', '2021-01-01', '2'),
	('B', '2021-01-02', '2'),
	('B', '2021-01-04', '1'),
	('B', '2021-01-11', '1'),
	('B', '2021-01-16', '3'),
	('B', '2021-02-01', '3'),
	('C', '2021-01-01', '3'),
	('C', '2021-01-01', '3'),
	('C', '2021-01-07', '3');

CREATE TABLE dannys_menu(
product_id INTEGER,
product_name VARCHAR(5),
price INTEGER
);

INSERT INTO dannys_menu
VALUES
	('1', 'sushi', '10'),
	('2', 'curry', '15'),
	('3', 'ramen', '12');
    
CREATE TABLE dannys_members(
customer_id VARCHAR(1),
join_date DATE
);

INSERT INTO dannys_members
VALUES
	('A', '2021-01-07'),
	('B', '2021-01-09');
    
SELECT * FROM dannys_sales;
SELECT * FROM dannys_menu;
SELECT * FROM dannys_members;   

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id AS Customer, sum(m.price) AS Total_Amount
FROM dannys_sales s
JOIN dannys_menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id AS Customer, COUNT(DISTINCT(order_date)) AS No_of_Days_Visited
FROM dannys_sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte_cust AS(
SELECT s.customer_id, s.order_date,m.product_id, m.product_name AS ITEM,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS RNK_NO
FROM dannys_menu m
JOIN dannys_sales s ON m.product_id = s.product_id)
select * from cte_cust
WHERE RNK_NO = 1
GROUP BY customer_id,product_id;

SET SESSION sql_mode = '';

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS Purchased_count
FROM dannys_sales s
JOIN dannys_menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY Purchased_count DESC
limit 1;

-- 5. Which item was the most popular for each customer?

WITH most_popular_item AS (
SELECT s.customer_id, m.product_name, COUNT(m.product_id) AS count_item,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) AS rnk_no
FROM dannys_sales s
JOIN dannys_menu m ON s.product_id = m.product_id
GROUP BY s.customer_id, m.product_name)
SELECT customer_id, product_name, count_item FROM most_popular_item
WHERE rnk_no = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH after_member_cte AS 
(
SELECT s.customer_id, s.product_id,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS RNK_NO
FROM dannys_sales s , dannys_members ms
WHERE s.customer_id = ms.customer_id
AND s.order_date >= ms.join_date
)
SELECT amc.customer_id, m.product_name 
FROM after_member_cte amc, dannys_menu m
WHERE amc.product_id = m.product_id
AND RNK_NO = 1
ORDER BY amc.customer_id;

-- 7. Which item was purchased just before the customer became a member?

WITH before_member_cte AS
(
SELECT s.customer_id, s.product_id,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS RNK_NO
FROM dannys_sales s
JOIN dannys_members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
)
SELECT bmc.customer_id , m.product_name
FROM before_member_cte bmc
JOIN dannys_menu m ON bmc.product_id = m.product_id
WHERE RNK_NO = 1
ORDER BY bmc.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id, COUNT(s.product_id) AS item_count,
SUM(m.price) AS amount_spent
FROM dannys_sales s
JOIN dannys_menu m ON s.product_id = m.product_id
JOIN dannys_members ms ON s.customer_id = ms.customer_id
WHERE s.order_date < ms.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
SUM(CASE 
	WHEN m.product_name = 'sushi' THEN 20 * m.price ELSE 10 * m.price 
END) AS Loyalty_Points
FROM dannys_sales s
JOIN dannys_menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT S.customer_id,
SUM(CASE
	WHEN M.product_name = 'sushi' THEN 20 * M.price
    WHEN (EXTRACT(DAY FROM s.order_date) - EXTRACT(DAY FROM MS.join_date)) 
    BETWEEN 0 AND 6 THEN 20 * M.price ELSE 10 * M.price
END) AS Loyalty_Points
FROM dannys_sales S
JOIN dannys_menu M ON S.product_id = M.product_id
JOIN dannys_members MS ON S.customer_id = MS.customer_id
WHERE EXTRACT(MONTH FROM S.order_date) = 1
GROUP BY S.customer_id
ORDER BY S.customer_id;


-- #BONUS Questions Join All the Things

CREATE VIEW JoinALL AS 
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE
	WHEN s.order_date < ms.join_date THEN 'N'
    WHEN s.order_date >= ms.join_date THEN 'Y'
    ELSE 'N'
END AS Member
FROM dannys_sales s
LEFT JOIN dannys_menu m ON s.product_id = m.product_id
LEFT JOIN dannys_members ms on s.customer_id = ms.customer_id;

SELECT * FROM JoinALL;

-- #Rank All Things

CREATE VIEW RankALL AS
SELECT * ,
CASE 
	WHEN Member = 'N' THEN NULL
    ELSE DENSE_RANK() OVER (PARTITION BY customer_id, Member ORDER BY order_date)
END AS Ranking
FROM JoinALL;

SELECT * FROM RankALL;