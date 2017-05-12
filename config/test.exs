use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ehealth, EHealth.Web.Endpoint,
  http: [port: 4001],
  server: true

config :ehealth, EHealth.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", "http://localhost:4040"}

# Configures PRM API
config :ehealth, EHealth.API.PRM,
  endpoint: {:system, "PRM_ENDPOINT", "http://localhost:4040"}

# Configures Man API
config :ehealth, EHealth.API.Man,
  endpoint: {:system, "MAN_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Mithril,
  endpoint: {:system, "OAUTH_ENDPOINT", "http://localhost:4040"}

config :ehealth, mock: [
  port: {:system, :integer, "TEST_MOCK_PORT", 4040},
  host: {:system, "TEST_MOCK_HOST", "localhost"}
]

# Print only warnings and errors during test
config :logger, level: :warn

# Run acceptance test in concurrent mode
config :ehealth, sql_sandbox: true

# Configure your database
config :ehealth, EHealth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
