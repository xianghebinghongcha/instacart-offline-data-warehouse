-- =====================================================
-- ODS 数据质量检查
-- =====================================================


SELECT '>>> 开始执行 ODS 数据质量检查';



-- 1. 数据量检查

SELECT '>>> 开始检查数据量';


select 
    'orders' as table_name,
    count(*) as cnt
from instacart_ods.ods_orders

union all

select 
    'products' as table_name,
    count(*) as cnt
from instacart_ods.ods_products;



SELECT '>>> 数据量检查完成';



-- 2. 重复值检查

SELECT '>>> 开始检查 orders 重复数据';


select 
    count(*) as duplicate_order_cnt
from
(
    select 
        order_id
    from instacart_ods.ods_orders
    group by order_id
    having count(*) > 1
)t;


SELECT '>>> orders 重复数据检查完成';



-- 3. 缺失值检查


SELECT '>>> 开始检查 orders 缺失值';


select 
    count(*) as order_id_null_cnt
from instacart_ods.ods_orders
where order_id is null;


SELECT '>>> orders 缺失值检查完成';



SELECT '>>> 开始检查 products 缺失值';


select 
    count(*) as product_null_cnt
from instacart_ods.ods_products
where product_id is null
   or product_name is null
   or aisle_id is null
   or department_id is null;


SELECT '>>> products 缺失值检查完成';



-- 4. 非法数值检查


SELECT '>>> 开始检查 orders 非法数值';


select 
    count(*) as invalid_order_cnt
from instacart_ods.ods_orders
where order_number <= 0
   or order_dow < 0
   or order_dow > 6
   or order_hour_of_day < 0
   or order_hour_of_day > 23
   or days_since_prior_order < 0;


SELECT '>>> orders 非法数值检查完成';

SELECT '>>> ODS 数据质量检查完成';
