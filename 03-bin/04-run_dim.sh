#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run_hive_sql "${SQL_DIR}/04-create_dim_tables.sql"
