#!/bin/bash -e
set -o pipefail

# コンテナのエントリポイント
# sqlserverの起動と初期セットアップ等を並列に実行します

/initdb.sh &

/printcon.sh &

/opt/mssql/bin/sqlservr
