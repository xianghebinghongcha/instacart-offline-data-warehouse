#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

LOG_DIR="${PROJECT_DIR}/logs"

mkdir -p "${LOG_DIR}"

RUN_TIME=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="${LOG_DIR}/etl_${RUN_TIME}.log"

# 执行 ETL 前确认日志文件可以打开。
if ! : >> "${LOG_FILE}"; then
    printf '无法打开日志文件：%s\n' "${LOG_FILE}" >&2
    exit 1
fi

# 保存原始输出；退出时关闭管道并等待 tee，检查日志是否写入成功。
exec 3>&1 4>&2
finish_logging() {
    local ETL_STATUS=$?
    local LOG_STATUS=0
    trap - EXIT
    exec 1>&3 2>&4 3>&- 4>&-
    wait "${LOG_PID}" || LOG_STATUS=$?
    if [ "${LOG_STATUS}" -ne 0 ]; then
        printf '日志写入失败（exit=%s）：%s\n' "${LOG_STATUS}" "${LOG_FILE}" >&2
        # 优先保留 ETL 的失败码，否则返回日志进程的失败码。
        if [ "${ETL_STATUS}" -eq 0 ]; then
            ETL_STATUS=${LOG_STATUS}
        fi
    fi
    exit "${ETL_STATUS}"
}

# 后面的所有输出，同时打印到屏幕，并写入日志。
exec > >(tee -a "${LOG_FILE}" 3>&- 4>&-) 2>&1
LOG_PID=$!
trap finish_logging EXIT

echo "========================================"
echo "电商离线数仓 ETL 开始"
echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "日志文件：${LOG_FILE}"
echo "========================================"

echo ""
echo "========== INIT HDFS =========="
bash "${SCRIPT_DIR}/01-init_hdfs.sh"

echo ""
echo "========== CREATE DATABASES =========="
bash "${SCRIPT_DIR}/02-run_databases.sh"

echo ""
echo "========== STEP 1 / 5: ODS =========="
bash "${SCRIPT_DIR}/03-run_ods.sh"

echo ""
echo "========== STEP 2 / 5: DIM =========="
bash "${SCRIPT_DIR}/04-run_dim.sh"

echo ""
echo "========== STEP 3 / 5: DWD =========="
bash "${SCRIPT_DIR}/05-run_dwd.sh"

echo ""
echo "========== STEP 4 / 5: DWS =========="
bash "${SCRIPT_DIR}/06-run_dws.sh"

echo ""
echo "========== STEP 5 / 5: ADS =========="
bash "${SCRIPT_DIR}/07-run_ads.sh"


echo ""
echo "========================================"
echo "电商离线数仓 ETL 全部执行完成"
echo "结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
