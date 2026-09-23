use instacart_dim;


-- =====================================================
-- dim_products 商品维度表
-- =====================================================

SELECT '>>> 开始创建 dim_products';

CREATE TABLE IF NOT EXISTS dim_products
(
    product_id BIGINT,
    product_name STRING,
    aisle_id BIGINT,
    department_id BIGINT
)
STORED AS ORC;

SELECT '>>> dim_products 创建完成';


SELECT '>>> 开始加载 dim_products 数据';

INSERT OVERWRITE TABLE dim_products

SELECT
    product_id,
    product_name,
    IF(aisle_id IS NULL, -1, aisle_id) AS aisle_id,
    IF(department_id IS NULL, -1, department_id) AS department_id

FROM
    instacart_ods.ods_products

WHERE
    product_id IS NOT NULL
    AND product_name IS NOT NULL;

SELECT '>>> dim_products 数据加载完成';


-- =====================================================
-- dim_aisles 货架维度表
-- =====================================================

SELECT '>>> 开始创建 dim_aisles';

CREATE TABLE IF NOT EXISTS dim_aisles
(
    aisle_id BIGINT,
    aisle STRING
)
STORED AS ORC;

SELECT '>>> dim_aisles 创建完成';


SELECT '>>> 开始加载 dim_aisles 数据';

INSERT OVERWRITE TABLE dim_aisles

SELECT
    aisle_id,
    aisle

FROM
    instacart_ods.ods_aisles

WHERE
    aisle_id IS NOT NULL;

SELECT '>>> dim_aisles 数据加载完成';


SELECT '>>> 开始加载 dim_aisles 数据';

INSERT INTO instacart_dim.dim_aisles
(
    aisle_id,
    aisle
)

SELECT
    -1,
    'unknown';

SELECT '>>> dim_aisles 数据加载完成';


-- =====================================================
-- dim_departments 部门维度表
-- =====================================================

SELECT '>>> 开始创建 dim_departments';

CREATE TABLE IF NOT EXISTS dim_departments
(
    department_id BIGINT,
    department STRING
)
STORED AS ORC;

SELECT '>>> dim_departments 创建完成';


SELECT '>>> 开始加载 dim_departments 数据';

INSERT OVERWRITE TABLE dim_departments

SELECT
    department_id,
    department

FROM
    instacart_ods.ods_departments

WHERE
    department_id IS NOT NULL;

SELECT '>>> dim_departments 数据加载完成';


SELECT '>>> 开始加载 dim_departments 数据';

INSERT INTO instacart_dim.dim_departments
(
    department_id,
    department
)

SELECT
    -1,
    'unknown';

SELECT '>>> dim_departments 数据加载完成';
