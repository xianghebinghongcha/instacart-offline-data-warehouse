-- =====================================================
-- ODS 外部表创建
-- =====================================================

use instacart_ods;


SELECT '>>> 开始创建 ods_orders';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_orders
(
    order_id BIGINT,
    user_id BIGINT,
    eval_set STRING,
    order_number INT,
    order_dow INT,
    order_hour_of_day INT,
    days_since_prior_order DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/orders'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_orders 创建完成';


SELECT '>>> 开始创建 ods_order_products_prior';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_order_products_prior
(
    order_id BIGINT,
    product_id BIGINT,
    add_to_cart_order INT,
    reordered INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/order_products_prior'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_order_products_prior 创建完成';


SELECT '>>> 开始创建 ods_order_products_train';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_order_products_train
(
    order_id BIGINT,
    product_id BIGINT,
    add_to_cart_order INT,
    reordered INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/order_products_train'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_order_products_train 创建完成';


SELECT '>>> 开始创建 ods_products';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_products
(
    product_id BIGINT,
    product_name STRING,
    aisle_id BIGINT,
    department_id BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/products'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_products 创建完成';


SELECT '>>> 开始创建 ods_aisles';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_aisles
(
    aisle_id BIGINT,
    aisle STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/aisles'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_aisles 创建完成';


SELECT '>>> 开始创建 ods_departments';

CREATE EXTERNAL TABLE IF NOT EXISTS instacart_ods.ods_departments
(
    department_id BIGINT,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/warehouse/instacart/source/departments'
TBLPROPERTIES (
    "skip.header.line.count"="1"
);

SELECT '>>> ods_departments 创建完成';
