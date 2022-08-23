select * from balanced_tree.dbo.sales


----------------------High Level Sales Analysis--------------


---1.What was the total quantity sold for all products?

select p.product_name , sum(s.qty) as Total_Qty from balanced_tree.dbo.sales as s inner join balanced_tree.dbo.product_details as p 
on s.prod_id = p.product_id group by p.product_name

---2.What is the total generated revenue for all products before discounts?
select * from balanced_tree.dbo.product_details
select * from balanced_tree.dbo.product_hierarchy
select * from balanced_tree.dbo.product_prices
select * from balanced_tree.dbo.sales

select p.product_name , sum(p.price * s.qty) as Total_revenue  from  balanced_tree.dbo.product_details as p inner join balanced_tree.dbo.sales as s on p.product_id = s.prod_id
group by p.product_name



----3.What was the total discount amount for all products?

select p.product_name , sum(s.discount) as Total_discounts  from  balanced_tree.dbo.product_details as p inner join balanced_tree.dbo.sales as s on p.product_id = s.prod_id
group by p.product_name

-------------Transaction Analysis-----------
----1.How many unique transactions were there?

select count(distinct(txn_id)) as Unique_transactions from balanced_tree.dbo.sales


-----2.What is the average unique products purchased in each transaction?
select p.product_name , avg(count(s.txn_id)) as Unique_transactions  from balanced_tree.dbo.product_details as p
inner join balanced_tree.dbo.sales as s on p.product_id = s.prod_id group by  p.product_name

--3.What are the 25th, 50th and 75th percentile values for the revenue per transaction?

select distinct( txn_id), percentile_cont(0.25) within group(order by price) over () as percentile_cont_25,
  percentile_cont(0.50) within group(order by price) over () as percentile_cont_50,
  percentile_cont(0.75) within group(order by price) over () as percentile_cont_75,
  percentile_cont(0.95) within group(order by price) over () as percentile_cont_95   from  balanced_tree.dbo.sales order by txn_id;


  ---4.What is the average discount value per transaction?

  select  txn_id , avg(discount) as Average_discount from balanced_tree.dbo.sales group by txn_id

  ---5.What is the percentage split of all transactions for members vs non-members?
  
 SELECT
  member,
  COUNT(DISTINCT txn_id) AS frequency,
  ROUND(
    100 *(
      COUNT(DISTINCT txn_id) / SUM(COUNT(DISTINCT txn_id)) OVER()
    ),
    2
  ) AS percentage
FROM
  balanced_tree.dbo.sales
GROUP BY
  member

--6.What is the average revenue for member transactions and non-member transactions?

WITH cte AS(
  SELECT
    txn_id,
    member,
    SUM((1 - discount / 100) * price * qty) AS total_revenue
  FROM
    balanced_tree.dbo.sales
  GROUP BY
    txn_id,
    member
)
SELECT
  member,
  ROUND(AVG(total_revenue), 2) AS avg_rev_by_member
FROM
  cte
GROUP BY
  member


------Product Analysis-----

--1.-What are the top 3 products by total revenue before discount?

select top 3 p.product_name , sum( s.price * s.qty) as Total_revenue from balanced_tree.dbo.sales as s 
inner join balanced_tree.dbo.product_details as p on s.prod_id = p.product_id group by p.product_name order by Total_revenue desc


---2.What is the total quantity, revenue and discount for each segment?

select p.segment_name , sum( s.qty) as Total_Quantity , sum(s.discount)as Total_Discount , sum(s.price * s.qty)as Total_Revenue
from balanced_tree.dbo.sales as s 
inner join balanced_tree.dbo.product_details as p on s.prod_id = p.product_id  group by p.segment_name order by Total_Revenue desc



---3.What is the top selling product for each segment?
with cte as (select *,  row_number() over ( partition by segment_name order by Total_revenue desc) as Row_numbers from(
select  p.segment_name, p.product_name , sum( s.price * s.qty) as Total_revenue from balanced_tree.dbo.sales as s 
inner join balanced_tree.dbo.product_details as p on s.prod_id = p.product_id group by  p.segment_name, p.product_name) as Groups)

select *  from cte where Row_numbers =1


---3.What is the total quantity, revenue and discount for each category?


select p.category_name , sum( s.qty) as Total_Quantity , sum(s.discount)as Total_Discount , sum(s.price * s.qty)as Total_Revenue
from balanced_tree.dbo.sales as s 
inner join balanced_tree.dbo.product_details as p on s.prod_id = p.product_id  group by p.category_name order by Total_Revenue desc

---4.What is the top selling product for each category?

with cte as (select *,  row_number() over ( partition by category_name order by Total_revenue desc) as Row_numbers from(
select  p.category_name, p.product_name , sum( s.price * s.qty) as Total_revenue from balanced_tree.dbo.sales as s 
inner join balanced_tree.dbo.product_details as p on s.prod_id = p.product_id group by  p.category_name, p.product_name) as Groups)

select *  from cte where Row_numbers =1


--5.What is the percentage split of revenue by product for each segment?

WITH cte AS (
  SELECT
    t2.segment_id,
    t2.segment_name,
    t2.product_id,
    t2.product_name,
    SUM(
      t1.price * t1.qty *(1 - t1.discount/ 100)
    ) AS total_rev
  FROM
    balanced_tree.dbo.sales t1
    INNER JOIN balanced_tree.dbo.product_details t2 ON t1.prod_id = t2.product_id
  GROUP BY
      t2.segment_id,
    t2.segment_name,
    t2.product_id,
    t2.product_name
)
SELECT
  segment_id,
  segment_name,
  product_id,
  product_name,
  ROUND(total_rev, 2) AS total_rev,
  ROUND(
    100 *(
      total_rev / SUM(total_rev) OVER(PARTITION BY segment_id)
    ),
    2
  ) AS percentage
FROM
  cte
ORDER BY
    segment_id,
   product_name DESC
