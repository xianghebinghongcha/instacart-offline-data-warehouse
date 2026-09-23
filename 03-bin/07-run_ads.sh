#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

run_hive_sql "${SQL_DIR}/07-create_ads_tables.sql"
