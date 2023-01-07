FROM mcr.microsoft.com/mssql/server:2019-latest

ENV MSSQL_PID="Developer"
ENV TZ="Asia/Tokyo"

COPY --chown=mssql ./scripts/ /

CMD ["/entrypoint.sh"]
