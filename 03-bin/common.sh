#!/bin/bash

# 公共环境配置，SQL 和脚本统一保存为 UTF-8。
BIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${BIN_DIR}/.." && pwd)"
SQL_DIR="${PROJECT_DIR}/02-sql"
DATA_DIR="${PROJECT_DIR}/01-data"
HIVE_BEELINE="${HIVE_BEELINE:-${HIVE_HOME:+${HIVE_HOME}/bin/}beeline}"

run_hive_sql() {
    local SQL_FILE="$1"
    local SQL_NAME="${SQL_FILE##*/}"
    local ERROR_LOG STATUS UTF8_LOCALE

    printf '[%s] 开始执行 %s\n\n' "$(date +%H:%M:%S)" "${SQL_NAME}"
    if [ ! -f "${SQL_FILE}" ]; then
        printf '[%s] %s FAILED：SQL 文件不存在\n' "$(date +%H:%M:%S)" "${SQL_NAME}" >&2
        return 1
    fi

    # 兼容 C.UTF-8 / C.utf8 / en_US.utf8 等不同系统命名。
    UTF8_LOCALE="$(locale -a 2>/dev/null | LC_ALL=C awk 'tolower($0) ~ /utf-?8$/ {print; exit}')"
    if [ -z "${UTF8_LOCALE}" ]; then
        printf '[%s] %s FAILED：系统没有可用的 UTF-8 locale\n' "$(date +%H:%M:%S)" "${SQL_NAME}" >&2
        return 1
    fi
    if ! ERROR_LOG="$(mktemp)"; then
        printf '[%s] %s FAILED：无法创建错误日志\n' "$(date +%H:%M:%S)" "${SQL_NAME}" >&2
        return 1
    fi

    # tsv2 去掉表格边框及表头，同时保留 ODS 检查的实际查询结果。
    # 将调用放在 if 内，确保调用方 set -e 时仍可输出失败详情。
    if LANG="${UTF8_LOCALE}" LC_ALL="${UTF8_LOCALE}" \
        HADOOP_CLIENT_OPTS="${HADOOP_CLIENT_OPTS:-} -Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8" \
        "${HIVE_BEELINE}" \
        --silent=true \
        --verbose=false \
        --force=false \
        --outputformat=tsv2 \
        --showHeader=false \
        -u "${HIVE_JDBC_URL:-jdbc:hive2://127.0.0.1:11000/default}" \
        -n "${HIVE_USER:-root}" \
        -f "${SQL_FILE}" \
        2> "${ERROR_LOG}"; then
        STATUS=0
    else
        STATUS=$?
    fi

    if [ "${STATUS}" -eq 0 ]; then
        printf '\n[%s] %s SUCCESS\n\n' "$(date +%H:%M:%S)" "${SQL_NAME}"
    else
        printf '\n[%s] %s FAILED (exit=%s)\n' "$(date +%H:%M:%S)" "${SQL_NAME}" "${STATUS}" >&2
        cat "${ERROR_LOG}" >&2
    fi
    rm -f "${ERROR_LOG}"
    return "${STATUS}"
}
