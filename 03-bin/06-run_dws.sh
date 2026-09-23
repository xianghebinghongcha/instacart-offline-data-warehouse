#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run_hive_sql "${SQL_DIR}/06-create_dws_tables.sql"
