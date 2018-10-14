use Mix.Config

config :core, Core.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "${DB_NAME}",
  username: "${DB_USER}",
  password: "${DB_PASSWORD}",
  hostname: "${DB_HOST}",
  port: "${DB_PORT}",
  pool_size: "${DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.PRMRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${PRM_DB_NAME}",
  username: "${PRM_DB_USER}",
  password: "${PRM_DB_PASSWORD}",
  hostname: "${PRM_DB_HOST}",
  port: "${PRM_DB_PORT}",
  pool_size: "${PRM_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  types: Core.PRM.PostgresTypes,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.FraudRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${FRAUD_DB_NAME}",
  username: "${FRAUD_DB_USER}",
  password: "${FRAUD_DB_PASSWORD}",
  hostname: "${FRAUD_DB_HOST}",
  port: "${FRAUD_DB_PORT}",
  pool_size: "${FRAUD_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  types: Core.Fraud.PostgresTypes,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :core, Core.EventManagerRepo,
  adapter: Ecto.Adapters.Postgres,
  database: "${EVENT_MANAGER_DB_NAME}",
  username: "${EVENT_MANAGER_DB_USER}",
  password: "${EVENT_MANAGER_DB_PASSWORD}",
  hostname: "${EVENT_MANAGER_DB_HOST}",
  port: "${EVENT_MANAGER_DB_PORT}",
  pool_size: "${EVENT_MANAGER_DB_POOL_SIZE}",
  timeout: 15_000,
  pool_timeout: 15_000,
  loggers: [{Ecto.LoggerJSON, :log, [:info]}]

config :kafka_ex, brokers: "${KAFKA_BROKERS_HOST}"
config :taskafka, :mongo, url: "${MONGO_DB_URL}"
