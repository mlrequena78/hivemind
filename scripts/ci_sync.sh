#!/bin/bash 

set -e
set -o pipefail

HIVEMIND_DB_NAME=$1
HIVEMIND_POSTGRESQL_CONNECTION_STRING=$2
HIVEMIND_SOURCE_HIVED_URL=$3
HIVEMIND_MAX_BLOCK=$4

PYTHONUSERBASE=./local-site

DB_NAME=${HIVEMIND_DB_NAME//-/_}
DB_NAME=${DB_NAME//\[/_}
DB_NAME=${DB_NAME//]/_}
DB_URL=$HIVEMIND_POSTGRESQL_CONNECTION_STRING/$DB_NAME
echo Corrected db name $DB_NAME
echo Corrected db url $DB_URL

# Reuse DB_NAME as name of symbolic link pointing local hive "binary".
HIVE_NAME=$DB_NAME

if [ -f hive_sync.pid ]; then
  kill -SIGINT `cat hive_sync.pid` || true;
  rm hive_sync.pid;
fi

kill -SIGINT `pgrep -f "$HIVE_NAME sync"` || true;
sleep 5
kill -9 `pgrep -f "$HIVE_NAME sync"` || true;

ls -l dist/*
rm -rf ./local-site
mkdir -p `python3 -m site --user-site`
python3 setup.py install --user --force
ln -sf ./local-site/bin/hive $HIVE_NAME
./$HIVE_NAME -h

echo Attempting to recreate database $DB_NAME
psql -U $POSTGRES_USER -h localhost -d postgres -c "DROP DATABASE IF EXISTS $DB_NAME;"
psql -U $POSTGRES_USER -h localhost -d postgres -c "CREATE DATABASE $DB_NAME;"

echo Attempting to starting hive sync using hived node: $HIVEMIND_SOURCE_HIVED_URL . Max sync block is: $HIVEMIND_MAX_BLOCK
echo Attempting to access database $DB_URL
./$HIVE_NAME sync --pid-file hive_sync.pid --test-max-block=$HIVEMIND_MAX_BLOCK --exit-after-sync --test-profile=False --steemd-url "$HIVEMIND_SOURCE_HIVED_URL" --database-url $DB_URL 2>&1 | tee -i hivemind-sync.log
rm hive_sync.pid
