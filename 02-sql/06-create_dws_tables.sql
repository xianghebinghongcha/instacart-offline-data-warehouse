use instacart_dws;


-- ============================================================
-- 一、订单主题
-- ============================================================

SELECT '>>> 开始创建 dws_order_summary';

create table if not exists dws_order_summary 
( 
    order_id             bigint, 
    product_cnt          bigint, 
    distinct_product_cnt bigint 
) 
stored as orc;

SELECT '>>> dws_order_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_order_summary 数据';

insert overwrite table dws_order_summary 
select 
    order_id, 
    count(product_id) as product_cnt, 
    count(distinct product_id) as distinct_product_cnt 
from 
    instacart_dwd.dwd_order_details 
group by 
    order_id;

SELECT '>>> dws_order_summary 数据加载完成'; 


-- ============================================================
-- 二、用户主题
-- ============================================================

SELECT '>>> 开始创建 dws_user_summary';

create table if not exists dws_user_summary( 
    user_id bigint, 
    order_cnt bigint, 
    product_cnt bigint, 
    distinct_product_cnt bigint, 
    reordered_cnt int, 
    avg_product_cnt double, 
    avg_prior_order double 
) 
stored as orc;

SELECT '>>> dws_user_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_user_summary 数据';

insert overwrite table dws_user_summary 
select 
    o.user_id, 
    count(distinct o.order_id) as order_cnt, 
    count(opd.product_id) as product_cnt, 
    count(distinct opd.product_id) as distinct_product_cnt, 
    sum(reordered) as reordered_cnt, 
    round(count(distinct opd.product_id)/count(distinct o.order_id), 2) as avg_product_cnt, 
    round(avg(o.days_since_prior_order), 2) as avg_prior_order 
from 
    instacart_dwd.dwd_orders o 
left join 
    instacart_dwd.dwd_order_product_detail opd 
on 
    o.order_id = opd.order_id 
group by 
    o.user_id;

SELECT '>>> dws_user_summary 数据加载完成'; 


SELECT '>>> 开始创建 dws_user_category_summary';

create table if not exists dws_user_category_summary( 
    user_id bigint, 
    department_id bigint, 
    aisle_id bigint, 
    product_id bigint, 
    product_cnt bigint, 
    reordered_cnt bigint 
) 
stored as orc;

SELECT '>>> dws_user_category_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_user_category_summary 数据';

insert overwrite table dws_user_category_summary 
select 
    user_id, 
    department_id, 
    aisle_id, 
    product_id, 
    count(product_id) as product_cnt, 
    count(reordered) as reordered_cnt 
from 
    instacart_dwd.dwd_order_product_detail 
group by user_id, department_id, aisle_id, product_id;

SELECT '>>> dws_user_category_summary 数据加载完成'; 


-- ============================================================
-- 三、商品主题
-- ============================================================

SELECT '>>> 开始创建 dws_product_summary';

create table if not exists dws_product_summary( 
    product_id bigint, 
    buyer_cnt bigint, 
    sale_cnt bigint, 
    reordered_cnt bigint 
) 
stored as orc;

SELECT '>>> dws_product_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_product_summary 数据';

insert overwrite table dws_product_summary 
select 
    product_id, 
    count(distinct user_id) as buyer_cnt, 
    count(product_id) as sale_cnt, 
    sum(reordered) as reordered_cnt 
from 
    instacart_dwd.dwd_order_product_detail 
group by 
    product_id;

SELECT '>>> dws_product_summary 数据加载完成'; 


-- ============================================================
-- 四、品类主题
-- ============================================================

SELECT '>>> 开始创建 dws_department_summary';

create table if not exists dws_department_summary( 
    department_id bigint, 
    department string, 
    buyer_cnt bigint, 
    order_cnt bigint, 
    reordered_ratio double 
) 
stored as orc;

SELECT '>>> dws_department_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_department_summary 数据';

insert overwrite table dws_department_summary
select /*+ MAPJOIN(dim)*/
    dim.department_id,
    dim.department,
    dwd.buyer_cnt,
    dwd.order_cnt,
    dwd.reordered_ratio
from(
    select
        department_id,
        count(distinct user_id) as buyer_cnt,
        count(distinct order_id) as order_cnt,
        avg(reordered) as reordered_ratio
    from
        instacart_dwd.dwd_order_product_detail
    group by
        department_id
    )dwd
join
    instacart_dim.dim_departments dim
on
    dim.department_id = dwd.department_id;

SELECT '>>> dws_department_summary 数据加载完成';


SELECT '>>> 开始创建 dws_aisle_summary';

create table if not exists dws_aisle_summary( 
    aisle_id bigint, 
    aisle string, 
    buyer_cnt bigint, 
    order_cnt bigint, 
    reordered_ratio double 
) 
stored as orc;

SELECT '>>> dws_aisle_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_aisle_summary 数据';

insert overwrite table dws_aisle_summary
select /*+ MAPJOIN(dim)*/
    dim.aisle_id,
    dim.aisle,
    dwd.buyer_cnt,
    dwd.order_cnt,
    dwd.reordered_ratio
from(
    select
        aisle_id,
        count(distinct user_id) as buyer_cnt,
        count(distinct order_id) as order_cnt,
        avg(reordered) as reordered_ratio
    from
        instacart_dwd.dwd_order_product_detail
    group by
        aisle_id
    )dwd
join
    instacart_dim.dim_aisles dim
on
    dim.aisle_id = dwd.aisle_id;

SELECT '>>> dws_aisle_summary 数据加载完成';


-- ============================================================
-- 五、时间主题
-- ============================================================

SELECT '>>> 开始创建 dws_dow_summary';

create table if not exists dws_dow_summary( 
    dow_id int, 
    buyer_cnt bigint, 
    order_cnt bigint 
) 
stored as orc;

SELECT '>>> dws_dow_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_dow_summary 数据';

insert overwrite table dws_dow_summary 
select 
    order_dow as dow_id, 
    count(distinct user_id) as buyer_cnt, 
    count(distinct order_id) as order_cnt 
from 
    instacart_dwd.dwd_orders 
group by 
    order_dow;

SELECT '>>> dws_dow_summary 数据加载完成'; 


SELECT '>>> 开始创建 dws_hour_summary';

create table if not exists dws_hour_summary( 
    hour_id int, 
    buyer_cnt bigint, 
    order_cnt bigint 
) 
stored as orc;

SELECT '>>> dws_hour_summary 创建完成'; 
 
SELECT '>>> 开始加载 dws_hour_summary 数据';

insert overwrite table dws_hour_summary 
select 
    order_hour_of_day as hour_id, 
    count(distinct user_id) as buyer_cnt, 
    count(distinct order_id) as order_cnt 
from 
    instacart_dwd.dwd_orders 
group by 
    order_hour_of_day;

SELECT '>>> dws_hour_summary 数据加载完成';
