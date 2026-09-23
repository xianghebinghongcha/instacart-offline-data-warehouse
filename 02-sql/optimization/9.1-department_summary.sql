-- 优化前
insert overwrite table dws_department_summary
select 
    dim.department_id,
    dim.department,
    count(distinct dwd.user_id) as buyer_cnt,
    count(distinct dwd.order_id) as order_cnt,
    avg(dwd.reordered) as reordered_ratio
from
    instacart_dwd.dwd_order_product_detail dwd
join
    instacart_dim.dim_departments dim
on
    dim.department_id = dwd.department_id
group by
    dim.department_id, dim.department;

-- 优化后
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
    