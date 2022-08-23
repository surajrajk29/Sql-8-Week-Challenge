---1.How many pizzas were ordered?---
select count(pizza_id)as No_of_Orders from Pizzas.dbo.customer_orders;

--2.How many unique customer orders were made?----

select customer_id , count(order_id) as Orders  from Pizzas.dbo.customer_orders group by customer_id;


--3.How many successful orders were delivered by each runner?----
update Pizzas.dbo.runner_orders
set cancellation = 'null'
where cancellation = '';

select runner_id , sum(Case when cancellation = 'null' then 1 else 0 end )as Orders from Pizzas.dbo.runner_orders
group by runner_id;


---4.How many of each type of pizza was delivered?

select p.pizza_name , sum(Case when r.cancellation = 'null' then 1 else 0 end )as Orders from Pizzas.dbo.runner_orders as o inner join Pizzas.dbo.runner_orders as r on o.order_id = r.order_id 
inner join Pizzas.dbo.customer_orders as c on o.order_id = c.order_id inner join 
Pizzas.dbo.pizza_names as p on c.pizza_id = p.pizza_id group by p.pizza_name;

---5.How many Vegetarian and Meatlovers were ordered by each customer?--

select c.customer_id , p.pizza_name , COUNT( c.order_id) as Total from Pizzas.dbo.runner_orders as o inner join Pizzas.dbo.runner_orders as r on o.order_id = r.order_id 
inner join Pizzas.dbo.customer_orders as c on o.order_id = c.order_id inner join 
Pizzas.dbo.pizza_names as p on c.pizza_id = p.pizza_id group by c.customer_id , p.pizza_name ;


--6.What was the maximum number of pizzas delivered in a single order?---
with cte as (
select c.order_id , sum(Case when r.cancellation = 'null' then 1 else 0 end) as Orders
from Pizzas.dbo.runner_orders as r inner join Pizzas.dbo.customer_orders as c on 
r.order_id = c.order_id group by c.order_id)

select *  from cte where Orders in ( select MAX(Orders) from cte);


----7.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select c.customer_id , sum(Case when c.exclusions <> 'null' or c.extras <> 'null' then 1 else 0 end) as one_change,
sum(CASE when c.exclusions = 'null' or c.extras = 'null' then 1 else 0 end ) as no_change 
from Pizzas.dbo.customer_orders as c inner join Pizzas.dbo.runner_orders as r on c.order_id = r.order_id 
where r.distance <> 'null' group by c.customer_id ;


----8.How many pizzas were delivered that had both exclusions and extras?--

select c.customer_id , sum(Case when c.exclusions <> 'null' and c.extras <> 'null'then 1 else 0 end )as Both     
from Pizzas.dbo.customer_orders as c inner join Pizzas.dbo.runner_orders as r on c.order_id = r.order_id where
r.distance <> 'null' group by c.customer_id;

----9.What was the total volume of pizzas ordered for each hour of the day?--

select DATEPART(hour,order_time) As hour_of_day, COUNT(order_id) As Pizza_count from Pizzas.dbo.customer_orders

group by DATEPART(hour,order_time);

--10.What was the volume of orders for each day of the week?--

SELECT FORMAT(DATEADD(DAY, 2, order_time),'dddd') AS day_of_week, 
-- add 2 to adjust 1st day of the week as Monday
 COUNT(order_id) AS total_pizzas_ordered
FROM Pizzas.dbo.customer_orders
GROUP BY FORMAT(DATEADD(DAY, 2, order_time),'dddd');





---------------------------B. Runner and Customer Experience--------------------------------

---1.How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)


select DATEPART( week, registration_date) , COUNT( runner_id) as Counts    from Pizzas.dbo.runners
group by DATEPART( week, registration_date) ;


--2.What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ 
---to pickup the order?

with cte as(
select DATEDIFF(MINUTE, c.order_time , r.pickup_time )as time_diff  from Pizzas.dbo.customer_orders as c join  Pizzas.dbo.runner_orders as r on c.order_id = r.order_id
where r.duration <> 'null') 

select AVG(time_diff) as Average_time  from cte where time_diff >1;


--3.Is there any relationship between the number of pizzas and how long the order takes to prepare?

select c.customer_id , c.pizza_id , r.order_id , r.pickup_time , DATEDIFF(minute, c.order_time, r.pickup_time) as Pizza_diff
from Pizzas.dbo.customer_orders as c join 
Pizzas.dbo.runner_orders as r on r.order_id = c.order_id where r.duration <> 'null'



---4.What was the average distance travelled for each customer?
UPDATE Pizzas.dbo.runner_orders
SET distance = LEFT(distance,DATALENGTH(distance)-(PATINDEX('%[0-9]%',REVERSE(distance))-1))

select c.customer_id , AVG(distance) as Avg_distance from Pizzas.dbo.runner_orders as r join
Pizzas.dbo.customer_orders as c on r.order_id = c.order_id where r.duration <> 'null' group by c.customer_id;


--5.What was the difference between the longest and shortest delivery times for all orders?--

select max(distance)as longest , min(distance) as shortest  from Pizzas.dbo.runner_orders where duration <>'null';


--6.What was the average speed for each runner for each delivery and do you notice any trend for these values?--



select runner_id , avg ( distance/duration) as Avg_speed from Pizzas.dbo.runner_orders group by runner_id;


--7.What is the successful delivery percentage for each runner?

SELECT runner_id, 
 ROUND(100 * SUM
  (CASE WHEN distance = 0 THEN 0
  ELSE 1
  END) / COUNT(*), 0) AS success_perc
FROM Pizzas.dbo.runner_orders
GROUP BY runner_id;



-----------------------C. Ingredient Optimisation--------------------------------

---1.What are the standard ingredients for each pizza?----
select * from Pizzas.dbo.pizza_recipes

---2.What was the most commonly added extra?----

select topping_name from Pizzas.dbo.customer_orders as o join Pizzas.dbo.pizza_toppings as t on t.topping_id like (o.extras);

---3.What was the most common exclusion?--
select topping_name from  Pizzas.dbo.pizza_toppings where topping_id =4; 

-----1.How many users are there?

select * from clique_bait.dbo.campaign_identifier
select * from clique_bait.dbo.event_identifier
select * from clique_bait.dbo.events
select * from clique_bait.dbo.page_hierarchy
select * from clique_bait.dbo.users


select count(distinct(user_id)) as [no of users] from clique_bait.dbo.users

---2.How many cookies does each user have on average?

with cte as (
select user_id , count(distinct(cookie_id)) as Coun_of_cookie from clique_bait.dbo.users group by user_id)

select avg(Coun_of_cookie) as [ Avg Cookie Each user has] from cte

----3.What is the unique number of visits by all users per month?

select DATENAME(month,event_time) as Months, count(distinct (visit_id)) as [no of unique vistors] from clique_bait.dbo.events 
group by DATENAME(month,event_time) 

---4.What is the number of events for each event type?
select  i.event_name, count(*) as [ No of Events] from clique_bait.dbo.event_identifier as i inner join
clique_bait.dbo.events as e on i.event_type = e.event_type group by  i.event_name



---How many times was each product viewed?
---How many times was each product added to cart?
---How many times was each product added to a cart but not purchased (abandoned)?
---How many times was each product purchased?//**//----

select * from clique_bait.dbo.campaign_identifier
select * from clique_bait.dbo.event_identifier
select * from clique_bait.dbo.events
select * from clique_bait.dbo.page_hierarchy
select * from clique_bait.dbo.users

--1.-How many times was each product viewed?
select p.product_category , count(distinct(e.visit_id)) as Counts
from clique_bait.dbo.events as e inner join clique_bait.dbo.page_hierarchy as p on e.page_id = p.page_id group by p.product_category


---How many times was each product added to cart?

select p.product_category , count( i.event_type) as Times from clique_bait.dbo.events as e inner join  clique_bait.dbo.event_identifier as i on e.event_type = i.event_type inner join 
clique_bait.dbo.page_hierarchy as p on e.page_id = p.page_id where i.event_name = 'Add to Cart' group by p.product_category

-----How many times was each product added to a cart but not purchased (abandoned)?

select u.user_id, i.event_name , p.page_name , p.product_category, e.event_time, RANK() over ( partition by u.user_id order by e.event_time)
from clique_bait.dbo.events as e inner join  clique_bait.dbo.event_identifier as i on e.event_type = i.event_type inner join 
clique_bait.dbo.page_hierarchy as p on e.page_id = p.page_id inner join clique_bait.dbo.users as u on e.cookie_id = u.cookie_id where i.event_name = 'Purchase'