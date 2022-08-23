select * from foodie_fi.dbo.plans
select * from foodie_fi.dbo.subscriptions

---------------B. Data Analysis Questions---------------

----1.How many customers has Foodie-Fi ever had?--

select count(distinct(customer_id)) as Total_customers from foodie_fi.dbo.subscriptions

----2.What is the monthly distribution of trial plan start_date values for our dataset 
-- use the start of the month as the group by value

select * from foodie_fi.dbo.plans
select * from foodie_fi.dbo.subscriptions

select DATEPART(month, start_dat) as monthly_dist, count(customer_id) as 'Values' 
from foodie_fi.dbo.subscriptions where plan_id = 0
group by  DATEPART(month, start_dat) order by monthly_dist;



---3.What plan start_date values occur after the year 2020 for our dataset? 
---Show the breakdown by count of events for each plan_name

select p.plan_name , count(s.customer_id) as Count_of_events from foodie_fi.dbo.plans as p join foodie_fi.dbo.subscriptions as s 
on p.plan_id = s.plan_id where s.start_dat >= '2020-01-01' group by p.plan_name;


--4.How many customers have churned straight after their initial free trial - 
--what percentage is this rounded to the nearest whole number?

select * from foodie_fi.dbo.plans
select * from foodie_fi.dbo.subscriptions

select count(*) as Total_Churn , round(100*count(*)/
(select count(distinct(customer_id) )from foodie_fi.dbo.subscriptions),1) as churn_percentage from foodie_fi.dbo.subscriptions as s
inner join foodie_fi.dbo.plans as p on s.plan_id = p.plan_id where p.plan_id = 4;


--4.What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
with ranking as (
select s.customer_id,p.plan_id, p.plan_name, row_number() over ( partition by s.customer_id order by  p.plan_id  ) as Ranks   
from foodie_fi.dbo.subscriptions as s
inner join foodie_fi.dbo.plans as p on s.plan_id = p.plan_id)

select count(*) as Churn_count , round(100* count(*)/ 
( select count(distinct(customer_id)) from foodie_fi.dbo.subscriptions ),0) as Churn_perecentage from ranking where 
plan_id = 4 and Ranks = 2


--5.What is the number and percentage of customer plans after their initial free trial?
with this as (SELECT 
  customer_id, 
  plan_id, 
  LEAD(plan_id, 1) OVER(
    PARTITION BY customer_id 
    ORDER BY plan_id) as next_plan
FROM foodie_fi.dbo.subscriptions)

SELECT 
  next_plan, 
  COUNT(*) AS conversions,
  ROUND(100 * COUNT(*) / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.dbo.subscriptions),1) AS conversion_percentage
FROM this
WHERE next_plan IS NOT NULL 
  AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

--7.What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?

WITH next_plan AS(
SELECT 
  customer_id, 
  plan_id, 
  start_dat,
  LEAD(start_dat, 1) OVER(PARTITION BY customer_id ORDER BY start_dat) as next_date
FROM foodie_fi.dbo.subscriptions
WHERE start_dat <= '2020-12-31'
),
-- Find customer breakdown with existing plans on or after 31 Dec 2020
customer_breakdown AS (
  SELECT 
    plan_id, 
    COUNT(DISTINCT customer_id) AS customers
  FROM next_plan
  WHERE 
    (next_date IS NOT NULL AND (start_dat < '2020-12-31' 
      AND next_date > '2020-12-31'))
    OR (next_date IS NULL AND start_dat < '2020-12-31')
  GROUP BY plan_id)

SELECT plan_id, customers, 
  ROUND(100 * customers / (
    SELECT COUNT(DISTINCT customer_id) 
    FROM foodie_fi.dbo.subscriptions),1) AS percentage
FROM customer_breakdown
GROUP BY plan_id, customers
ORDER BY plan_id;

---8.How many customers have upgraded to an annual plan in 2020?

select count(distinct(customer_id)) as Total from foodie_fi.dbo.subscriptions 
where plan_id = 3 and start_dat <= '2020-12-31' ;

--9.How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

with trail as(
select start_dat as trail_date, customer_id from foodie_fi.dbo.subscriptions where plan_id =0 )

, annual_plan as ( select start_dat as Annual_start , customer_id from foodie_fi.dbo.subscriptions where plan_id =3)

select round( avg(DATEDIFF(day,trail_date,Annual_start)),0) as Average_customers from trail as t  join annual_plan as p on 
t.customer_id = p.customer_id

--10.Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)

with trail as(
select start_dat as trail_date, customer_id from foodie_fi.dbo.subscriptions where plan_id =0 )

, annual_plan as ( select start_dat as Annual_start , customer_id from foodie_fi.dbo.subscriptions where plan_id =3)

,bins as ( select DATE_BUCKET




----C. Challenge Payment Question----


