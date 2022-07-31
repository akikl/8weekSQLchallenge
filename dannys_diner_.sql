-- 1.Total amount each customer spent at the restaurant 
select
    customer_id,sum(price) 'Total_Amount_Spent'
from
    menu m
        inner join
    sales s on m.product_id = s.product_id
group by customer_id;
-- 2. No of Days each customer has visited the restaurant
select
    customer_id, count(distinct (order_date))
from
    sales
group by customer_id;

-- 3.The first item from the menu purchased by each customer
with order_detail_cte as(select customer_id,product_name,dense_rank() over(partition by customer_id order by order_date )as first_item from sales s inner join menu m on s.product_id=m.product_id)

select customer_id,product_name from order_detail_cte where first_item=1 group by customer_id,product_name ;
-- 4.The most purchased item on the menu and no of times it was purchased by all customers
select
    count(s.product_id) as order_count, product_name
from
    sales s
        inner join
    menu m on s.product_id = m.product_id
group by product_name
order by order_count desc
limit 1; 

-- 5.The most popular item for each customer
with order_details_cte as (select product_name,count(product_name)as order_count,customer_id,rank() over(partition by s.customer_id order by count(product_name) desc) as item_count from sales s inner join menu m on s.product_id=m.product_id group by customer_id,product_name)
select customer_id,product_name,order_count from order_details_cte where item_count=1 ;
-- 6.Item that was purchased first by the customer after they became a member
select s.customer_id,product_name,order_date from sales s inner join menu m on s.product_id=m.product_id inner join members me on s.customer_id=me.customer_id where order_date >=join_date group by customer_id ;
-- 7.Item  that was purchased just before the customer became a member
with prior_member_cte as
(
select s.customer_id, join_date, order_date, product_id,
         dense_rank() over(partition by customer_id
         order by order_date desc) as mem_rank
from sales s
 inner join members m
  on s.customer_id = m.customer_id
where s.order_date < m.join_date
)

select customer_id,product_name from prior_member_cte pm inner join menu me on pm.product_id=me.product_id  where mem_rank=1 ;


-- 8.The total items and amount spent for each member before they became a member

select s.customer_id,count(distinct(product_name)),sum(price) from sales s inner join menu m on s.product_id=m.product_id inner join members me on s.customer_id=me.customer_id where order_date < join_date group by customer_id;

-- 9.Points of Each customer(If each $1 spent equates to 10 points and sushi has a 2x points multiplier)
with points_cte as(select *,
case when product_id=1 then  20*price
else  price*10
end as points
from menu)
select customer_id,sum(p.points)Totalpoints from points_cte p inner join sales s on s.product_id = p.product_id group by customer_id;


-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
-- how many points do customer A and B have at the end of January

with date_cte as(select customer_id,join_date,DATE_ADD(join_date, INTERVAL 6 DAY)as member_week from members)
select dt.customer_id,order_date,member_week,sum(case when order_date between join_date and member_week then price*2*10
when product_name="sushi" then price*2*10
when product_name="sushi" and order_date not between join_date and member_week then price*2*10
else price*10
end )as points from date_cte dt inner join sales s on dt.customer_id=s.customer_id inner join menu m on s.product_id = m.product_id where order_date<'2021-01-31' group by customer_id;
