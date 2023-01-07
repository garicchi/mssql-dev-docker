#!/bin/bash
set -o pipefail

# sqlserverを初期化するスクリプト

SCRIPT_PATH=$(cd $(dirname $0); pwd)

if [[ -z ${RDB_ROOT_PASS} ]]; then
  echo "env RDB_ROOT_PASS does not set" >&2
  exit 1
fi

if [[ -z ${RDB_NAME} ]]; then
  echo "env RDB_NAME does not set" >&2
  exit 1
fi

if [[ -z ${RDB_USER} ]]; then
  echo "env RDB_USER does not set" >&2
  exit 1
fi

if [[ -z ${RDB_PASS} ]]; then
  echo "env RDB_PASS does not set" >&2
  exit 1
fi

echo "attempt and wait to connect database..."
IS_SUCCESS=false
for I in $(seq 30); do
  /opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U sa -P ${RDB_ROOT_PASS} -Q ""
  if [[ $? = 0 ]]; then
    IS_SUCCESS=true
    break
  fi
  sleep 1
done

if [[ ${IS_SUCCESS} = false ]]; then
  echo "could not connect database" >&2
  exit 1
fi

echo "success to connect database!"

/opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U sa -P ${RDB_ROOT_PASS} -Q "IF DB_ID('${RDB_NAME}') IS NULL raiserror('', 17, -1)" > /dev/null

if [[ $? = 0 ]]; then
  echo "database [${RDB_NAME}] has already been initialized! skip to init"
  exit 0
fi

echo "⚡start to initialize [${RDB_NAME}]"

/opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U sa -P ${RDB_ROOT_PASS} -Q "
IF DB_ID('${RDB_NAME}') IS NULL
  CREATE DATABASE ${RDB_NAME}
GO

USE ${RDB_NAME}
GO

IF SUSER_ID('${RDB_USER}') IS NULL
  CREATE LOGIN ${RDB_USER}
  WITH
    PASSWORD = \"${RDB_PASS}\",
    CHECK_POLICY = OFF
GO

IF USER_ID('${RDB_USER}') IS NULL
  CREATE USER ${RDB_USER} FOR LOGIN ${RDB_USER}
GO

GRANT ALTER, CONTROL, DELETE, EXECUTE, INSERT, REFERENCES, SELECT, UPDATE
  ON DATABASE::${RDB_NAME} TO ${RDB_USER}
GO
"

INITDB_PATH=/docker-entrypoint-initdb.d
if [[ -e "${INITDB_PATH}" ]]; then
  find "${INITDB_PATH}" -name "*.sql" | sort | while read FILE; do
    echo "⚡execute init script [${FILE}]"
    /opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U ${RDB_USER} -P ${RDB_PASS} -d ${RDB_NAME} -i "${FILE}"
  done
else
  echo "could not find any initial script in ${INITDB_PATH}. skip execute init sql."
fi

echo "🍺 completed!"
