#!/bin/bash

set -e

BASE_HDFS=/warehouse/instacart/source
BASE_LOCAL=/mnt/public/code/zyh/bigdata_env/01-instacart/01-data

tables=(
orders
order_products_prior
order_products_train
products
aisles
departments
)

echo "========== 创建HDFS目录 =========="

for item in ${tables[@]}
do
    hdfs dfs -mkdir -p ${BASE_HDFS}/${item}
done


echo "========== 上传数据 =========="

for item in ${tables[@]}
do
    # 判断文件是否存在
    if hdfs dfs -test -e ${BASE_HDFS}/${item}/${item}.csv
    then
        echo "${item}.csv 已存在，跳过"
    else
        echo "上传 ${item}.csv"

        hdfs dfs -put \
        ${BASE_LOCAL}/${item}.csv \
        ${BASE_HDFS}/${item}/
    fi

done


echo "========== 数据上传完成 =========="