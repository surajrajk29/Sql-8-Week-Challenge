-----Case Study #4 - Data Bank-----

select * from data_bank.dbo.customer_nodes order by customer_id;
select * from data_bank.dbo.customer_transactions
select * from data_bank.dbo.regions;


--------------.A. Customer Nodes Exploration------------------------

---1.How many unique nodes are there on the Data Bank system?

select count(distinct(node_id)) as Unique_Nodes from data_bank.dbo.customer_nodes;


---2.What is the number of nodes per region?

select r.region_name , count(node_id) as No_of_Nodes
from data_bank.dbo.customer_nodes as n inner join data_bank.dbo.regions as r on n.region_id = r.region_id
group by r.region_name;

---3.How many customers are allocated to each region?

select r.region_name, count(distinct(n.customer_id)) as No_of_Customers

from data_bank.dbo.customer_nodes as n inner join data_bank.dbo.regions as r on n.region_id = r.region_id
group by r.region_name;


---4.How many days on average are customers reallocated to a different node?--

with node_diff as (

select customer_id, node_id , start_date, end_date, datediff(DAY,start_date,end_date) as Diff_date  
from data_bank.dbo.customer_nodes where end_date <> '9999-12-31' group by customer_id, node_id, start_date, end_date
),
sum_diff as (
select customer_id, node_id, sum(Diff_date) as Sum_diff   from node_diff group by customer_id, node_id)

select ROUND(avg(Sum_diff),2) as Avg_reallocation_inDays from sum_diff;


---5.What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with node_diff as (

select customer_id, node_id ,region_id ,start_date, end_date, datediff(DAY,start_date,end_date) as Diff_date  
from data_bank.dbo.customer_nodes where end_date <> '9999-12-31'  group by customer_id, node_id,region_id, start_date, end_date
)
select customer_id, node_id,region_id, sum(Diff_date) as Sum_diff   from node_diff group by customer_id, node_id , region_id

---------------------------B. Customer Transactions-------------------------


-----1.What is the unique count and total amount for each transaction type?

select txn_type , sum(txn_amount)as Total_amount , count(distinct(customer_id)) as Unique_count   from data_bank.dbo.customer_transactions
group by txn_type;


----2.What is the average total historical deposit counts and amounts for all customers?
with deposits as (
select customer_id, txn_type , count(*) as txn_counts , avg(txn_amount) as avg_amount 
from data_bank.dbo.customer_transactions group by customer_id, txn_type)

select round(avg(txn_counts),0)as Txn_counts , round(avg(avg_amount),0) as Avg_amount from deposits where txn_type ='deposit';

----3.For each month - how many Data Bank customers make more than 1 deposit and either 
---1 purchase or 1 withdrawal in a single month?
with txt_type as(
select  customer_id , DATEPART(month,txn_date)as Months,
sum(case when txn_type = 'deposit' then 1 else 0 end) as deposits_count,
sum(case when txn_type = 'withdrawal' then 1 else 0 end) as withdrawal_count,
sum(case when txn_type = 'purchase' then 1 else 0 end) as purchase_count 
from data_bank.dbo.customer_transactions group by customer_id , DATEPART(month,txn_date))

select Months , count(distinct(customer_id)) as Counts from txt_type where deposits_count >2 and 
(purchase_count >1 or withdrawal_count >1) group by Months order by Months


---4.What is the closing balance for each customer at the end of the month?

with txn as (
select customer_id , txn_type , EOMONTH(txn_date,0) as end_of_month ,sum(case when txn_type ='deposit' then txn_amount else 0 end) as deposits,
sum(case when txn_type = 'purchase' or txn_type = 'withdrawal' then txn_amount else 0 end) as other_balances  from data_bank.dbo.customer_transactions 
group by  customer_id , txn_type,EOMONTH(txn_date,0) )
select customer_id ,end_of_month, sum( deposits - other_balances) as closing_balance from txn group by customer_id, end_of_month having customer_id <=2 
order by customer_id ;


----5.What is the percentage of customers who increase their closing balance by more than 5%?
with txn as (select *, MIN(txn_date) over ( partition by customer_id, (DATEPART(month , txn_date))) as Starting_Months from data_bank.dbo.customer_transactions ),
starting_months as (
select customer_id, txn_type, Starting_Months ,sum(case when txn_type ='deposit' then txn_amount else 0 end) as deposits,
sum(case when txn_type = 'purchase' or txn_type = 'withdrawal' then txn_amount else 0 end) as other_balances  from txn
group by customer_id, txn_type, Starting_Months)

select customer_id, Starting_Months ,sum( deposits - other_balances) as Starting_balance   from starting_months
group by customer_id, Starting_Months having customer_id <=2 order by customer_id ;
select * from data_bank.dbo.customer_transactions where customer_id <= 2 order by customer_id ;