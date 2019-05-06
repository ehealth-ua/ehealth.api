use Mix.Config

config :core, Core.ReadRepo,
  database: {:system, :string, "READ_DB_NAME"},
  username: {:system, :string, "READ_DB_USER"},
  password: {:system, :string, "READ_DB_PASSWORD"},
  hostname: {:system, :string, "READ_DB_HOST"},
  port: {:system, :integer, "READ_DB_PORT"},
  pool_size: {:system, :integer, "READ_DB_POOL_SIZE", 10},
  timeout: 15_000

config :core, Core.Repo,
  database: {:system, :string, "DB_NAME"},
  username: {:system, :string, "DB_USER"},
  password: {:system, :string, "DB_PASSWORD"},
  hostname: {:system, :string, "DB_HOST"},
  port: {:system, :integer, "DB_PORT"},
  pool_size: {:system, :integer, "DB_POOL_SIZE", 10},
  timeout: 15_000

config :core, Core.ReadPRMRepo,
  database: {:system, :string, "READ_PRM_DB_NAME"},
  username: {:system, :string, "READ_PRM_DB_USER"},
  password: {:system, :string, "READ_PRM_DB_PASSWORD"},
  hostname: {:system, :string, "READ_PRM_DB_HOST"},
  port: {:system, :integer, "READ_PRM_DB_PORT"},
  pool_size: {:system, :integer, "READ_PRM_DB_POOL_SIZE", 10},
  timeout: 15_000,
  types: Core.PRM.PostgresTypes

config :core, Core.PRMRepo,
  database: {:system, :string, "PRM_DB_NAME"},
  username: {:system, :string, "PRM_DB_USER"},
  password: {:system, :string, "PRM_DB_PASSWORD"},
  hostname: {:system, :string, "PRM_DB_HOST"},
  port: {:system, :integer, "PRM_DB_PORT"},
  pool_size: {:system, :integer, "PRM_DB_POOL_SIZE", 10},
  timeout: 15_000,
  types: Core.PRM.PostgresTypes

config :core, Core.FraudRepo,
  database: {:system, :string, "FRAUD_DB_NAME"},
  username: {:system, :string, "FRAUD_DB_USER"},
  password: {:system, :string, "FRAUD_DB_PASSWORD"},
  hostname: {:system, :string, "FRAUD_DB_HOST"},
  port: {:system, :integer, "FRAUD_DB_PORT"},
  pool_size: {:system, :integer, "FRAUD_DB_POOL_SIZE", 10},
  timeout: 15_000,
  types: Core.Fraud.PostgresTypes

config :kaffe,
  producer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["deactivate_declaration_events", "merge_legal_entities", "event_manager_topic"]
  ]
