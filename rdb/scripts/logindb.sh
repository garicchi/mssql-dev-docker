#!/bin/bash -e
set -o pipefail

/opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U ${RDB_USER} -P ${RDB_PASS} -d ${RDB_NAME} $@