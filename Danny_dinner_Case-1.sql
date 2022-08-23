select * from danny.dbo.members;
select * from danny.dbo.menu;
select * from danny.dbo.sales;

--1.What is the total amount each customer spent at the restaurant?--

select s.customer_id , sum(m.price) as Total_Amount_spent from danny.dbo.sales as s inner join danny.dbo.menu as m
on s.product_id = m.product_id group by s.customer_id;

--2.How many days has each customer visited the restaurant?--

select customer_id , count (distinct( order_date)) as No_of_Days  from danny.dbo.sales group by customer_id;


---3.What was the first item from the menu purchased by each customer?----

with amd as (select s.customer_id, m.product_name  , ROW_NUMBER() over ( partition by s.customer_id order by s.order_date)as Row_num
from danny.dbo.sales as s inner join danny.dbo.menu as m
on s.product_id = m.product_id)

select  customer_id ,product_name from amd where Row_num =1;


--4.What is the most purchased item on the menu and how many times was it purchased by all customers?--

with cte as (select  m.product_name , ROW_NUMBER() over ( partition by s.product_id order by m.product_name) as Counts
from danny.dbo.sales as s inner join danny.dbo.menu as m
on s.product_id = m.product_id)
select product_name , count(Counts) as Total from cte group by product_name having count(Counts) >6


---5.Which item was the most popular for each customer?---
WITH fav_item_cte AS
(
 SELECT s.customer_id, m.product_name, 
  COUNT(m.product_id) AS order_count,
  DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM danny.dbo.menu AS m
JOIN danny.dbo.sales AS s
 ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)
select customer_id , product_name from fav_item_cte where rank =1 ;

--6.Which item was purchased first by the customer after they became a member?--
with cte as (
select m.customer_id ,  s.order_date , e.product_name  , m.join_date, DENSE_RANK() over (partition by m.customer_id order by s.order_date)
as Counts from danny.dbo.members as m inner join danny.dbo.sales as s  on s.customer_id = m.customer_id and
s.order_date >= m.join_date inner join danny.dbo.menu as e on s.product_id = e.product_id)

select * from cte where Counts =1;

--7.Which item was purchased just before the customer became a member?---

with cte as (
select m.customer_id ,  s.order_date , e.product_name  , m.join_date, DENSE_RANK() over (partition by m.customer_id order by s.order_date desc)
as Counts from danny.dbo.members as m inner join danny.dbo.sales as s  on s.customer_id = m.customer_id and
s.order_date >= m.join_date inner join danny.dbo.menu as e on s.product_id = e.product_id)

select * from cte where Counts =1;

--8.What is the total items and amount spent for each member before they became a member?---

select m.customer_id , count(s.product_id) as Total_items, sum(e.price) as Amount_spent from danny.dbo.sales as s inner join danny.dbo.members as m on s.customer_id = m.customer_id and
s.order_date < m.join_date inner join danny.dbo.menu as e on s.product_id = e.product_id group by m.customer_id ;


--09.If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
--how many points would each customer have?

with cte as (
select m.customer_id , e.product_name ,  Case when e.product_name = 'sushi' then POWER(e.price, 2) else e.price*10 end as Points
from danny.dbo.members as m inner join danny.dbo.sales as s  on s.customer_id = m.customer_id and
s.order_date >= m.join_date inner join danny.dbo.menu as e on s.product_id = e.product_id)

select customer_id , sum (Points)  from cte group by customer_id;

----Without memembers---
with cte as (
select s.customer_id, m.product_name ,Case when m.product_name = 'sushi' then POWER(m.price, 2) else m.price*10 end as Points

from danny.dbo.sales as s inner join danny.dbo.menu as m on s.product_id = m.product_id)
select customer_id , SUM(Points)   from cte group by customer_id;


--10.In the first week after a customer joins the program (including their join date)
--they earn 2x points on all items, not just sushi - how many points do 
--customer A and B have at the end of January?--



---customer_id	order_date	product_name	price	member---
with cte as (
select s.customer_id , s.order_date , e.product_name , e.price , 
Case when m.join_date > s.order_date then 'N' when m.join_date < = s.order_date then 'Y' else 'N' end as Members 
from danny.dbo.sales as s left join danny.dbo.members as m  on s.customer_id = m.customer_id inner join
danny.dbo.menu as e on s.product_id = e.product_id )

select *, Case when Members = 'N' then Null else DENSE_RANK() over
( partition by customer_id, Members order by order_date) end as Rankings from cte;