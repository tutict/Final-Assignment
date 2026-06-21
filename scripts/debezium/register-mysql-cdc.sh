#!/usr/bin/env bash
set -euo pipefail

CONNECT_URL="${DEBEZIUM_CONNECT_URL:-http://localhost:8083}"
CONNECTOR_NAME="${MYSQL_CDC_CONNECTOR_NAME:-traffic-mysql-source}"
DB_HOST="${MYSQL_CDC_HOST:-host.docker.internal}"
DB_PORT="${MYSQL_CDC_PORT:-3306}"
DB_USER="${MYSQL_CDC_USER:-debezium}"
DB_PASSWORD="${MYSQL_CDC_PASSWORD:-}"
DB_NAME="${MYSQL_CDC_DATABASE:-traffic}"
TOPIC_PREFIX="${MYSQL_CDC_TOPIC_PREFIX:-traffic}"

if [ -z "$DB_PASSWORD" ]; then
  echo "MYSQL_CDC_PASSWORD is required. Create a MySQL CDC user and expose its password before registering the connector." >&2
  exit 1
fi

TABLES="$DB_NAME.driver_information,$DB_NAME.vehicle_information,$DB_NAME.sys_user,$DB_NAME.appeal_record,$DB_NAME.payment_record,$DB_NAME.fine_record,$DB_NAME.deduction_record,$DB_NAME.offense_record"

curl -fsS -X PUT "$CONNECT_URL/connectors/$CONNECTOR_NAME/config" \
  -H "Content-Type: application/json" \
  -d "{
    \"connector.class\": \"io.debezium.connector.mysql.MySqlConnector\",
    \"tasks.max\": \"1\",
    \"database.hostname\": \"$DB_HOST\",
    \"database.port\": \"$DB_PORT\",
    \"database.user\": \"$DB_USER\",
    \"database.password\": \"$DB_PASSWORD\",
    \"topic.prefix\": \"$TOPIC_PREFIX\",
    \"database.include.list\": \"$DB_NAME\",
    \"table.include.list\": \"$TABLES\",
    \"include.schema.changes\": \"false\",
    \"snapshot.mode\": \"initial\",
    \"tombstones.on.delete\": \"false\",
    \"time.precision.mode\": \"connect\",
    \"decimal.handling.mode\": \"string\",
    \"schema.history.internal.kafka.bootstrap.servers\": \"redpanda:29092\",
    \"schema.history.internal.kafka.topic\": \"schema-changes.$DB_NAME\",
    \"key.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
    \"value.converter\": \"org.apache.kafka.connect.json.JsonConverter\",
    \"key.converter.schemas.enable\": \"false\",
    \"value.converter.schemas.enable\": \"false\"
  }"

echo "Registered Debezium connector '$CONNECTOR_NAME' at $CONNECT_URL"
