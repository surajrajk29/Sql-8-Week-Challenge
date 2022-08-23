--------------1. Data Cleansing Steps----------

select * from data_mart.dbo.weekly_sales;

select   convert(date, week_date,3) as week_date ,
DATEPART(WEEK,  convert(date, week_date,3)) as week_number,
DATEPART(month, convert(date, week_date,3)) as month_number,
DATEPART(year, convert(date, week_date,3)) as Year_number,
region, platform, segment,

Case when RIGHT(segment,1) = '1' then 'Young Adults'
	 when RIGHT(segment,1) = '2' then 'Middle aged'
	 when right(segment, 1) in ('3','4') then 'Retirees'
	 else 'unknown' end as age_band,
Case when left(segment,1) = 'C' then 'Couples'
	when left(segment,1) = 'F' then 'Families'
	else 'unknown' end as demographics,	 
	 transactions,
	 round((sales/transactions),2) as Avg_transaction , sales  into data_mart.dbo.Clean_weekly_sales 
from data_mart.dbo.weekly_sales


-------------------------2. Data Exploration------------------------
---1.What day of the week is used for each week_date value?

select distinct(datename(WEEKDAY,week_date)) as  'day of the week' from data_mart.dbo.Clean_weekly_sales


---2.What range of week numbers are missing from the dataset?--

select distinct(week_number) from data_mart.dbo.Clean_weekly_sales;

 with CTE as  
(  
 select 1 Number  
 union all  
 select Number +1 from CTE where Number<53  
)
select * from cte where Number not in (select distinct(week_number) from data_mart.dbo.Clean_weekly_sales)


---3.How many total transactions were there for each year in the dataset?

select Year_number , sum(transactions) as total_transactions from data_mart.dbo.Clean_weekly_sales group by Year_number order by Year_number


---4.What is the total sales for each region for each month?
select region, month_number, SUM(CAST(sales AS BIGINT)) as 'Total Sales' from data_mart.dbo.Clean_weekly_sales group by region, month_number order by region, month_number ;

---5.What is the total count of transactions for each platform---
select platform,  count (transactions) as 'total count of transactions' from data_mart.dbo.Clean_weekly_sales group by platform;


--6.What is the percentage of sales for Retail vs Shopify for each month?-
with cte as (
select  distinct(month_number),platform, case when platform = 'Retail' then SUM(CAST(sales AS BIGINT)) over (partition by platform order by month_number) end as Retail_Sales, 
case when platform = 'Shopify' then SUM(CAST(sales AS BIGINT)) over (partition by platform order by month_number) end as Shopify_Sales,
SUM(CAST(sales AS BIGINT)) over (partition by month_number) as Total_Sales
from data_mart.dbo.Clean_weekly_sales )

select month_number , platform, round(( Retail_Sales / Total_Sales )*100,2)  as Retail_Percentage , round(( Shopify_Sales /Total_Sales)*100,2) as Shopify_percentage
from cte

---7.What is the percentage of sales by demographic for each year in the dataset?
with cte as (
select distinct(Year_number),case when demographics = 'Couples' then SUM(CAST(sales AS BIGINT)) over (partition by Year_number) end as Couples_Sales,
case when demographics = 'Families' then SUM(CAST(sales AS BIGINT)) over (partition by Year_number,demographics) end as Families_Sales,
case when demographics = 'unknown' then SUM(CAST(sales AS BIGINT)) over (partition by Year_number,demographics) end as unknown_Sales,
 SUM(CAST(sales AS BIGINT)) over (partition by Year_number) as Total_Sales
from data_mart.dbo.Clean_weekly_sales)
select distinct(Year_number ), round (( Couples_Sales/Total_Sales)*100,2)as Couples_Percent  , round ((Families_Sales /Total_Sales)*100,2) as Families_percet,
   round ((unknown_Sales /Total_Sales)*100,2) as unknown_percet from cte order by Year_number

---8.Which age_band and demographic values contribute the most to Retail sales?

select top 1  platform, age_band, demographics , SUM(CAST(sales AS BIGINT)) as total_sales from data_mart.dbo.Clean_weekly_sales  where platform = 'Retail'
group by platform, age_band, demographics order by total_sales desc


---9.Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? 
---If not - how would you calculate it instead?
select  Year_number ,PLATFORM, avg(count(transactions)) over (Partition by year_number, platform) Average_Transactions   from data_mart.dbo.Clean_weekly_sales 
group by Year_number ,PLATFORM;



select * from data_mart.dbo.Clean_weekly_sales where week_date >= '2020-06-15';

SUM(CAST(sales AS BIGINT))

-----------------3. Before & After Analysis----------

---What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
select region , sum(cast(case when week_date <  '2020-06-15' then (sales as bigint )end)as before_sales,
sum(case when week_date >=  '2020-06-15' then sales end )as after_sales
    from data_mart.dbo.Clean_weekly_sales  group by region



