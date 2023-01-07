# mssql-dev-docker

Microsoft SQL Serverの開発環境向けデータベースをdockerで起動するサンプルです。
docker compose upでサーバーを起動でき、起動時に環境変数で指定したデータベースやユーザーを自動作成するので
ASP.NET Core開発時にSQL Serverをローカルで使いたい場合などに便利です。

## Getting Started

[SQL ServerのEnd User License Agreement(EULA)](https://hub.docker.com/_/microsoft-mssql-server)に同意してください。
同意した場合、 `docker-compose.yml` の `# ACCEPT_EULA: "Y"` をコメントアウトしてください。

```diff
    environment:
      # ライセンスに同意する場合はコメントアウトしてください
      # c.f. https://hub.docker.com/_/microsoft-mssql-server
-     # ACCEPT_EULA: "Y"
+     ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: ${RDB_ROOT_PASS}
```

`.env.template` をコピーして `.env` を作成してください。

```sh
$ cp .env.temaplte .env
```

`.env` に、データベースのユーザー名やパスワードを指定してください。

|環境変数名|説明|
|:---:|:---:|
|RDB_ROOT_PASS|SQL ServerのSAアカウント(ルートアカウント)のパスワードになります [パスワードポリシー](https://learn.microsoft.com/ja-jp/sql/relational-databases/security/password-policy?view=sql-server-ver16#password-complexity)に記載されている複雑さが必要になります|
|RDB_NAME|データベースの名前です。この名前で起動時に自動作成されます|
|RDB_USER|データベースに接続するユーザー名です|
|RDB_PASS|データベースに接続するパスワードです|

`docker compose up` でサーバーを起動してください

```sh
# -dを付けるとバックグラウンドで起動
$ docker compose up
```

下記コマンドで接続文字列を確認できます
```sh
$ docker compose exec rdb /printcon.sh

-----------------------------------------------
⚡example connection string⚡
Server=tcp:localhost,1433;Initial Catalog=tes...
-----------------------------------------------
```

`docker compose stop` でサーバーを停止できます。

```sh
$ docker compose stop
```

`docker compose down --volumes` でコンテナを破棄します(データも破棄します)

```sh
$ docker compose down --volumes
```

## 初期化スクリプトを流したい

起動時に1回だけテーブルを作ったり、ストアドプロシージャを設定したりなどしたい場合があります。

その場合は、コンテナ内の `/docker-entrypoint-initdb.d` に `.sql` のファイルを入れたフォルダをマウントしてもらえれば初期化時の最後に自動実行します。

このサンプルでは `./rdb/initdb.d` が `/docker-entrypoint-initdb.d` にマウントしています。

## おまけ解説

[MySQLのOfficial docker image](https://hub.docker.com/_/mysql)は、環境変数を指定するとデフォルトのデータベースやユーザーを自動で作ってくれます。
そのおかげでコンテナを立ち上げるだけですぐにDBを利用でき、便利です。

しかしSQL Serverのdocker imageにはデータベースの自動作成機能はありません。

そこで、コンテナのエントリポイントを変更し、起動時に1度だけ、初期化スクリプトを実行します。

#### ./rdb/scripts/entrypoint.sh
```sh
# コンテナのエントリポイント
# sqlserverの起動と初期セットアップ等を並列に実行します

/initdb.sh &

/printcon.sh &

/opt/mssql/bin/sqlservr
```

この時、SQL Serverが立ち上がってから初期化スクリプトを実行したいので、初期化スクリプトの実行は、SQL Serverが起動完了した後でないといけません。

そこで、 `initdb.sh` ではsqlcmdを1秒に1回実行して、SQL Serverの起動完了を待機します。
```sh
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
```

さらに、 `DB_ID()` でデータベースがあるかどうかを判定し、存在すればすでに初期化済みということで初期化をスキップします。
```sh
/opt/mssql-tools/bin/sqlcmd -b -S 'localhost,1433' -U sa -P ${RDB_ROOT_PASS} -Q "IF DB_ID('${RDB_NAME}') IS NULL raiserror('', 17, -1)" > /dev/null

if [[ $? = 0 ]]; then
  echo "database [${RDB_NAME}] has already been initialized! skip to init"
  exit 0
fi
```
これで2回目以降の起動時に再度初期化スクリプトが実行されず、冪等性が保たれます。