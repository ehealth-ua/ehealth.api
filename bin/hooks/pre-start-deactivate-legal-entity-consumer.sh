APP_NAME="deactivate_legal_entity_consumer"

if [ "${KAFKA_MIGRATE}" == "true" ] && [ -f "./bin/${APP_NAME}" ]; then
  echo "[WARNING] Migrating kafka topics!"
  ./bin/$APP_NAME command  Elixir.Core.KafkaTasks migrate
fi;
