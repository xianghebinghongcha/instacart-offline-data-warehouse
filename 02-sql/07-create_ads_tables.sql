use instacart_ads;

SELECT '>>> 开始执行 ADS ETL';

-- ==================== 核心指标主题 ====================

SELECT '>>> 开始创建 ads_ecommerce_dashboard';

create table if not exists ads_ecommerce_dashboard(
    total_order_cnt bigint,
    total_buyer_cnt bigint,
    total_product_cnt bigint,
    total_aisle_cnt bigint,
    total_department_cnt bigint,
    overall_reorder_rate double
)
stored as orc;

SELECT '>>> ads_ecommerce_dashboard 创建完成';

SELECT '>>> 开始加载 ads_ecommerce_dashboard 数据';

insert overwrite table ads_ecommerce_dashboard
select
    o.total_order_cnt,
    u.total_buyer_cnt,
    p.total_product_cnt,
    a.total_aisle_cnt,
    d.total_department_cnt,
    ps.overall_reorder_rate
from
(
    select
        count(*) as total_order_cnt
    from instacart_dws.dws_order_summary
) o
join
(
    select
        count(*) as total_buyer_cnt
    from instacart_dws.dws_user_summary
) u
on 1=1
join
(
    select
        count(*) as total_product_cnt
    from instacart_dim.dim_products
) p
on 1=1
join
(
    select
        count(*) as total_aisle_cnt
    from instacart_dim.dim_aisles
) a
on 1=1
join
(
    select
        count(*) as total_department_cnt
    from instacart_dim.dim_departments
) d
on 1=1
join
(
    select
        round(
            cast(sum(reordered_cnt) as double)
            /
            sum(sale_cnt),
            2
        ) as overall_reorder_rate
    from instacart_dws.dws_product_summary
) ps
on 1=1;

SELECT '>>> ads_ecommerce_dashboard 数据加载完成';

-- ==================== 用户主题 ====================

SELECT '>>> 开始创建 ads_user_purchase_behavior';

create table if not exists ads_user_purchase_behavior(
    user_id bigint,
    order_cnt bigint,
    product_cnt bigint,
    distinct_product_cnt bigint,
    avg_product_cnt double,
    reordered_ratio double,
    avg_prior_order double
)
stored as orc;

SELECT '>>> ads_user_purchase_behavior 创建完成';

SELECT '>>> 开始加载 ads_user_purchase_behavior 数据';

insert overwrite table ads_user_purchase_behavior
select
    user_id,
    order_cnt,
    product_cnt,
    distinct_product_cnt,
    avg_product_cnt,
    round(reordered_cnt*1.0/order_cnt, 2) as reordered_ratio,
    avg_prior_order
from
    instacart_dws.dws_user_summary;

SELECT '>>> ads_user_purchase_behavior 数据加载完成';

SELECT '>>> 开始创建 ads_user_frequency';

create table if not exists ads_user_frequency(
    user_id bigint,
    order_cnt bigint,
    avg_order_cycle double,
    frequency_group string
) stored as orc;

SELECT '>>> ads_user_frequency 创建完成';

SELECT '>>> 开始加载 ads_user_frequency 数据';

with t1 as(
    select
        user_id,
        order_cnt,
        avg_prior_order as avg_order_cycle,
        ntile(5) over(order by order_cnt desc, avg_prior_order) as frequency_level
    from
        instacart_dws.dws_user_summary
    where
        order_cnt > 2
),
t2 as(
    select
        user_id,
        order_cnt,
        avg_prior_order as avg_order_cycle,
        '低订单用户' as frequency_group
    from
        instacart_dws.dws_user_summary
    where
        order_cnt <= 2
)
insert overwrite table ads_user_frequency
select
    user_id,
    order_cnt,
    avg_order_cycle,
    case
        when frequency_level = 1 then '高频购物用户'
        when frequency_level = 5 then '低频购物用户'
        else '普通用户'
    end as frequency_group
from
    t1
union all
select
    user_id,
    order_cnt,
    avg_order_cycle,
    frequency_group
from
    t2;

SELECT '>>> ads_user_frequency 数据加载完成';

SELECT '>>> 开始创建 ads_user_reordered';

create table if not exists ads_user_reordered(
    user_id bigint,
    purchase_cnt bigint,
    first_purchase_cnt bigint,
    reordered_purchase_cnt bigint,
    reordered_ratio double
)
stored as orc;

SELECT '>>> ads_user_reordered 创建完成';

SELECT '>>> 开始加载 ads_user_reordered 数据';

insert overwrite table ads_user_reordered
select
    user_id,
    product_cnt as purchase_cnt,
    product_cnt - reordered_cnt as first_purchase_cnt,
    reordered_cnt as reordered_purchase_cnt,
    round(reordered_cnt*1.0/product_cnt, 2) as reordered_ratio
from
    instacart_dws.dws_user_summary;

SELECT '>>> ads_user_reordered 数据加载完成';

SELECT '>>> 开始创建 ads_user_category_preference';

create table if not exists ads_user_category_preference(
    user_id bigint,
    top1_department string,
    top1_aisle string,
    top1_product string,
    top1_reordered_product string
)
stored as orc;

SELECT '>>> ads_user_category_preference 创建完成';

SELECT '>>> 开始加载 ads_user_category_preference 数据';

with product_rank as(
    select /*+ mapjoin(dim)*/
        dws.user_id,
        dim.product_name,
        dws.product_cnt,
        row_number() over (partition by dws.user_id order by dws.product_cnt desc) as p_rk
    from
        instacart_dws.dws_user_category_summary dws
    join
        instacart_dim.dim_products dim
    on
        dws.product_id = dim.product_id
),
product_reordered as(
    select /*+ mapjoin(dim)*/
        dws.user_id,
        dim.product_name,
        sum(dws.reordered_cnt) as reordered_cnt,
        row_number() over (partition by dws.user_id order by sum(dws.reordered_cnt) desc) as pr_rk
    from
        instacart_dws.dws_user_category_summary dws
    join
        instacart_dim.dim_products dim
    on
        dws.product_id = dim.product_id
    group by dws.user_id, dws.product_id, dim.product_name
),
aisle_rank as(
    select /*+ mapjoin(dim)*/
        dws.user_id,
        dim.aisle,
        sum(dws.product_cnt) as aisle_cnt,
        row_number() over (partition by dws.user_id order by sum(dws.product_cnt) desc) as a_rk
    from
        instacart_dws.dws_user_category_summary dws
    join
        instacart_dim.dim_aisles dim
    on
        dws.aisle_id = dim.aisle_id
    group by dws.user_id, dim.aisle
),
department_rank as(
    select /*+ mapjoin(dim)*/
        dws.user_id,
        dim.department,
        sum(dws.product_cnt) as department_cnt,
        row_number() over (partition by dws.user_id order by sum(dws.product_cnt) desc) as d_rk
    from
        instacart_dws.dws_user_category_summary dws
    join
        instacart_dim.dim_departments dim
    on
        dws.department_id = dim.department_id
    group by dws.user_id, dim.department
),
product_top as(
    select *
    from product_rank
    where p_rk=1
)
insert overwrite table ads_user_category_preference
select
    pt.user_id,
    dk.department as top1_department,
    ak.aisle as top1_aisle,
    pt.product_name as top1_product,
    pd.product_name as top1_reordered_product
from
    product_top pt
left join department_rank dk on pt.user_id = dk.user_id and dk.d_rk = 1
left join aisle_rank ak on pt.user_id = ak.user_id and ak.a_rk = 1
left join product_reordered pd on pt.user_id = pd.user_id and pd.pr_rk = 1;

SELECT '>>> ads_user_category_preference 数据加载完成';

SELECT '>>> 开始创建 ads_user_value_group';

create table if not exists ads_user_value_group(
    user_id bigint,
    order_cnt bigint,
    product_cnt bigint,
    distinct_product_cnt bigint,
    reordered_ratio double,
    value_score double,
    user_group string
) stored as orc;

SELECT '>>> ads_user_value_group 创建完成';

SELECT '>>> 开始加载 ads_user_value_group 数据';

with score as(
    select
        user_id,
        order_cnt,
        ntile(5) over(order by order_cnt) as order_cnt_score,
        product_cnt,
        ntile(5) over(order by product_cnt) as product_cnt_score,
        distinct_product_cnt,
        ntile(5) over(order by distinct_product_cnt) as distinct_product_cnt_score,
        round(reordered_cnt*1.0/product_cnt, 2) as reordered_ratio,
        ntile(5) over(order by reordered_cnt*1.0/product_cnt) as reordered_ratio_score
    from
        instacart_dws.dws_user_summary
),
value as(
    select
        user_id,
        order_cnt,
        product_cnt,
        distinct_product_cnt,
        reordered_ratio,
        (0.3*order_cnt_score
            +0.25*product_cnt_score
            +0.15*distinct_product_cnt_score
            +0.3*reordered_ratio_score) as value_score
    from
        score
)
insert overwrite table ads_user_value_group
select
    user_id,
    order_cnt,
    product_cnt,
    distinct_product_cnt,
    reordered_ratio,
    round(value_score, 2) as value_score,
    case
        when value_score >= 4.0 then '高价值用户'
        when value_score >= 3.0 then '活跃用户'
        when value_score >= 2.0 then '普通用户'
        else '低活跃用户'
    end as user_group
from
    value;

SELECT '>>> ads_user_value_group 数据加载完成';

-- ==================== 商品主题 ====================

SELECT '>>> 开始创建 ads_product_rank';

create table if not exists ads_product_rank(
    product_id bigint,
    purchase_cnt bigint,
    buyer_cnt bigint,
    purchase_cnt_rank int
)
stored as orc;

SELECT '>>> ads_product_rank 创建完成';

SELECT '>>> 开始加载 ads_product_rank 数据';

insert overwrite table ads_product_rank
select
    product_id,
    sale_cnt as purchase_cnt,
    buyer_cnt,
    row_number() over (order by sale_cnt desc) as purchase_cnt_rank
from
    instacart_dws.dws_product_summary;

SELECT '>>> ads_product_rank 数据加载完成';

SELECT '>>> 开始创建 ads_product_reordered';

create table if not exists ads_product_reordered(
    product_id bigint,
    purchase_cnt bigint,
    first_purchase_cnt bigint,
    reordered_purchase_cnt bigint,
    reordered_ratio double,
    reordered_group string
)
stored as orc;

SELECT '>>> ads_product_reordered 创建完成';

SELECT '>>> 开始加载 ads_product_reordered 数据';

with product_level as(
    select
        product_id,
        sale_cnt as purchase_cnt,
        sale_cnt - reordered_cnt as first_purchase_cnt,
        reordered_cnt as reordered_purchase_cnt,
        round(reordered_cnt*1.0/sale_cnt, 2) as reordered_ratio,
        ntile(5) over(order by reordered_cnt*1.0/sale_cnt desc) as reordered_level
    from
        instacart_dws.dws_product_summary
    where
        sale_cnt > 2
)
insert overwrite table ads_product_reordered
select
    product_id,
    purchase_cnt,
    first_purchase_cnt,
    reordered_purchase_cnt,
    reordered_ratio,
    case
        when reordered_level = 1 then '高复购商品'
        when reordered_level = 5 then '低复购商品'
        else '普通商品'
    end as reordered_group
from
    product_level
union all
select
    product_id,
    sale_cnt as purchase_cnt,
    sale_cnt - reordered_cnt as first_purchase_cnt,
    reordered_cnt as reordered_purchase_cnt,
    round(reordered_cnt*1.0/sale_cnt, 2) as reordered_ratio,
    '低销量商品' as reordered_group
from
    instacart_dws.dws_product_summary
where
    sale_cnt <= 2;

SELECT '>>> ads_product_reordered 数据加载完成';

SELECT '>>> 开始创建 ads_product_value_group';

create table if not exists ads_product_value_group(
    product_id bigint,
    buyer_cnt bigint,
    sale_cnt bigint,
    reordered_ratio double,
    value_group string
)
stored as orc;

SELECT '>>> ads_product_value_group 创建完成';

SELECT '>>> 开始加载 ads_product_value_group 数据';

with score as(
    select
        product_id,
        buyer_cnt,
        ntile(5) over(order by buyer_cnt) as buyer_cnt_score,
        sale_cnt,
        ntile(5) over(order by sale_cnt) as sale_cnt_score,
        round(reordered_cnt*1.0/sale_cnt, 2) as reordered_ratio,
        ntile(5) over(order by reordered_cnt*1.0/sale_cnt) as reordered_score
    from
        instacart_dws.dws_product_summary
    where
        sale_cnt > 2
),
value_score as(
    select
        product_id,
        buyer_cnt,
        buyer_cnt_score,
        sale_cnt,
        sale_cnt_score,
        reordered_ratio,
        reordered_score,
        (0.3*buyer_cnt_score
            +0.35*sale_cnt_score
            +0.35*reordered_score) as level
    from
        score
)
insert overwrite table ads_product_value_group
select
    product_id,
    buyer_cnt,
    sale_cnt,
    reordered_ratio,
    case
        when level >= 4 then '核心商品'
        when reordered_score > 4 then '高复购商品'
        when buyer_cnt_score > 4 or sale_cnt_score > 4 then '热门商品'
        else '长尾商品'
    end as value_group
from
    value_score
union all
select
    product_id,
    buyer_cnt,
    sale_cnt,
    round(reordered_cnt*1.0/sale_cnt, 2) as reordered_ratio,
    '长尾商品' as value_group
from
    instacart_dws.dws_product_summary
where
    sale_cnt <= 2;

SELECT '>>> ads_product_value_group 数据加载完成';

-- ==================== 订单与时间主题 ====================

SELECT '>>> 开始创建 ads_order_analysis';

create table if not exists ads_order_analysis(
    order_id bigint,
    product_cnt bigint,
    order_level int,
    order_group string
)
stored as orc;

SELECT '>>> ads_order_analysis 创建完成';

SELECT '>>> 开始加载 ads_order_analysis 数据';

with t as(
    select
        order_id,
        product_cnt,
        ntile(5) over(order by product_cnt desc) as order_level
    from
        instacart_dws.dws_order_summary
)
insert overwrite table ads_order_analysis
select
    order_id,
    product_cnt,
    order_level,
    case
        when order_level = 1 then '大订单'
        when order_level = 5 then '小订单'
        else '普通订单'
    end as order_group
from
    t;

SELECT '>>> ads_order_analysis 数据加载完成';

SELECT '>>> 开始创建 ads_dow_analysis';

create table if not exists ads_dow_analysis(
    dow_id int,
    buyer_cnt bigint,
    buyer_cnt_ratio double,
    order_cnt bigint,
    order_cnt_ratio double
)
stored as orc;

SELECT '>>> ads_dow_analysis 创建完成';

SELECT '>>> 开始加载 ads_dow_analysis 数据';

insert overwrite table ads_dow_analysis
select
    dow_id,
    buyer_cnt,
    round(buyer_cnt*1.0/sum(buyer_cnt) over(), 2) as buyer_cnt_ratio,
    order_cnt,
    round(order_cnt*1.0/sum(order_cnt) over(), 2) as order_cnt_ratio
from
    instacart_dws.dws_dow_summary;

SELECT '>>> ads_dow_analysis 数据加载完成';

SELECT '>>> 开始创建 ads_hour_analysis';

create table if not exists ads_hour_analysis(
    hour_id int,
    buyer_cnt bigint,
    buyer_cnt_ratio double,
    order_cnt bigint,
    order_cnt_ratio double
)
stored as orc;

SELECT '>>> ads_hour_analysis 创建完成';

SELECT '>>> 开始加载 ads_hour_analysis 数据';

insert overwrite table ads_hour_analysis
select
    hour_id,
    buyer_cnt,
    round(buyer_cnt*1.0/sum(buyer_cnt) over(), 4) as buyer_cnt_ratio,
    order_cnt,
    round(order_cnt*1.0/sum(order_cnt) over(), 4) as order_cnt_ratio
from
    instacart_dws.dws_hour_summary;

SELECT '>>> ads_hour_analysis 数据加载完成';

-- ==================== 品类主题 ====================

SELECT '>>> 开始创建 ads_department_analysis';

create table if not exists ads_department_analysis(
    department string,
    buyer_cnt bigint,
    order_cnt bigint,
    reordered_ratio double,
    order_cnt_rk int,
    reordered_group string
)
stored as orc;

SELECT '>>> ads_department_analysis 创建完成';

SELECT '>>> 开始加载 ads_department_analysis 数据';

with department_level as(
    select
        department,
        buyer_cnt,
        order_cnt,
        round(reordered_ratio, 2) as reordered_ratio,
        row_number() over (order by order_cnt desc) as order_cnt_rk,
        ntile(5) over(order by reordered_ratio desc) as level
    from
        instacart_dws.dws_department_summary
    where
        order_cnt > 2
)
insert overwrite table ads_department_analysis
select
    department,
    buyer_cnt,
    order_cnt,
    reordered_ratio,
    order_cnt_rk,
    case
        when level = 1 then '高复购'
        when level = 5 then '低复购'
        else '普通'
    end as reordered_group
from
    department_level
union all
select
    department,
    buyer_cnt,
    order_cnt,
    round(reordered_ratio, 2),
    row_number() over (order by order_cnt desc) as order_cnt_rk,
    '低订单' as reordered_group
from
    instacart_dws.dws_department_summary
where
    order_cnt <= 2;

SELECT '>>> ads_department_analysis 数据加载完成';

SELECT '>>> 开始创建 ads_aisle_analysis';

create table if not exists ads_aisle_analysis(
    aisle string,
    buyer_cnt bigint,
    order_cnt bigint,
    reordered_ratio double,
    order_cnt_rk int,
    reordered_group string
)
stored as orc;

SELECT '>>> ads_aisle_analysis 创建完成';

SELECT '>>> 开始加载 ads_aisle_analysis 数据';

with aisle_level as(
    select
        aisle,
        buyer_cnt,
        order_cnt,
        round(reordered_ratio, 2) as reordered_ratio,
        row_number() over (order by order_cnt desc) as order_cnt_rk,
        ntile(5) over(order by reordered_ratio desc) as level
    from
        instacart_dws.dws_aisle_summary
    where
        order_cnt > 2
)
insert overwrite table ads_aisle_analysis
select
    aisle,
    buyer_cnt,
    order_cnt,
    reordered_ratio,
    order_cnt_rk,
    case
        when level = 1 then '高复购'
        when level = 5 then '低复购'
        else '普通'
    end as reordered_group
from
    aisle_level
union all
select
    aisle,
    buyer_cnt,
    order_cnt,
    round(reordered_ratio, 2),
    row_number() over (order by order_cnt desc) as order_cnt_rk,
    '低订单' as reordered_group
from
    instacart_dws.dws_aisle_summary
where
    order_cnt <= 2;

SELECT '>>> ads_aisle_analysis 数据加载完成';
    

SELECT '>>> ADS ETL 全部完成';
