#!/bin/bash -e
set -o pipefail

# 接続文字列の例を表示します

# docker composeログの一番下に出るように3秒待機する
sleep 3

echo "-----------------------------------------------"
echo "⚡example connection string⚡"
echo "Server=tcp:localhost,1433;Initial Catalog=${RDB_NAME};User ID=${RDB_USER};Password=${RDB_PASS};Persist Security Info=False;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=True;Connection Timeout=30;"
echo "-----------------------------------------------"
