#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run_hive_sql "${SQL_DIR}/02-create_ods_tables.sql"

run_hive_sql "${SQL_DIR}/03-ods_check.sql"
