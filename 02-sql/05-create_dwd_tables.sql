use instacart_dwd;


-- =====================================================
-- dwd_orders 订单事实表
-- =====================================================


SELECT '>>> 开始创建 dwd_orders';

CREATE TABLE IF NOT EXISTS dwd_orders
(
    order_id BIGINT,
    user_id BIGINT,
    eval_set STRING,
    order_number INT,
    order_dow INT,
    order_hour_of_day INT,
    days_since_prior_order DOUBLE
)
STORED AS ORC;

SELECT '>>> dwd_orders 创建完成';


SELECT '>>> 开始加载 dwd_orders 数据';

INSERT OVERWRITE TABLE dwd_orders

SELECT
    order_id,
    user_id,
    eval_set,
    order_number,
    order_dow,
    order_hour_of_day,
    IF(days_since_prior_order IS NULL,
       0,
       days_since_prior_order) AS days_since_prior_order

FROM
    instacart_ods.ods_orders

WHERE
    order_id IS NOT NULL;

SELECT '>>> dwd_orders 数据加载完成';


-- =====================================================
-- dwd_order_details 订单商品明细表
-- =====================================================


SELECT '>>> 开始创建 dwd_order_details';

CREATE TABLE IF NOT EXISTS instacart_dwd.dwd_order_details
(
    order_id BIGINT,
    product_id BIGINT,
    add_to_cart_order INT,
    reordered INT,
    eval_set STRING
)
STORED AS ORC;

SELECT '>>> dwd_order_details 创建完成';


SELECT '>>> 开始加载 dwd_order_details 数据';

INSERT OVERWRITE TABLE instacart_dwd.dwd_order_details

SELECT
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    'prior' AS eval_set

FROM
    instacart_ods.ods_order_products_prior

WHERE
    order_id IS NOT NULL
    AND reordered IN (0, 1)


UNION ALL


SELECT
    order_id,
    product_id,
    add_to_cart_order,
    reordered,
    'train' AS eval_set

FROM
    instacart_ods.ods_order_products_train

WHERE
    order_id IS NOT NULL
    AND reordered IN (0, 1);

SELECT '>>> dwd_order_details 数据加载完成';


-- =====================================================
-- dwd_order_product_detail 商品订单明细宽表
-- =====================================================


SELECT '>>> 开始创建 dwd_order_product_detail';

CREATE TABLE IF NOT EXISTS instacart_dwd.dwd_order_product_detail
(
    order_id BIGINT,
    user_id BIGINT,
    product_id BIGINT,
    order_number INT,
    aisle_id BIGINT,
    department_id BIGINT,
    reordered INT
)
STORED AS ORC;

SELECT '>>> dwd_order_product_detail 创建完成';


SELECT '>>> 开始加载 dwd_order_product_detail 数据';

INSERT OVERWRITE TABLE instacart_dwd.dwd_order_product_detail

SELECT /*+ MAPJOIN(p) */

    o.order_id,
    o.user_id,
    od.product_id,
    o.order_number,
    p.aisle_id,
    p.department_id,
    od.reordered

FROM
    instacart_dwd.dwd_order_details od

JOIN
    instacart_dwd.dwd_orders o

ON
    od.order_id = o.order_id

JOIN
    instacart_dim.dim_products p

ON
    od.product_id = p.product_id;

SELECT '>>> dwd_order_product_detail 数据加载完成';
