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

# Configures OPS API
config :ehealth, EHealth.API.OPS,
  endpoint: {:system, "OPS_ENDPOINT", "http://localhost:4040"}

# Configures UAdress API
config :ehealth, EHealth.API.UAddress,
  endpoint: {:system, "UADDRESS_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Mithril,
  endpoint: {:system, "OAUTH_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.OTPVerification,
  endpoint: {:system, "OTP_VERIFICATION_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.MPI,
  endpoint: {:system, "MPI_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Gandalf,
  endpoint: {:system, "GNDF_ENDPOINT", "http://localhost:4040"}

config :ehealth, EHealth.API.Signature,
  endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT", "http://localhost:4040"}

config :ehealth, mock: [
  port: {:system, :integer, "TEST_MOCK_PORT", 4040},
  host: {:system, "TEST_MOCK_HOST", "localhost"}
]

# Configures declaration request terminator
config :ehealth, EHealth.DeclarationRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

# Configures employee request terminator
config :ehealth, EHealth.EmployeeRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

config :ehealth, EHealth.Bamboo.Mailer,
  adapter: Bamboo.TestAdapter

# Run acceptance test in concurrent mode
config :ehealth, sql_sandbox: true

# Don't start terminator in test env
config :ehealth, run_declaration_request_terminator: false

# Configure your database
config :ehealth, EHealth.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ehealth_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 120_000_000

config :ehealth, EHealth.PRMRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "prm_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  types: EHealth.PRM.PostgresTypes,
  ownership_timeout: 120_000_000
