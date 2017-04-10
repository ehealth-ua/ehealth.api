use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true


# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ehealth, EHealth.Web.Endpoint,
  http: [port: 4001],
  server: true

# Print only warnings and errors during test
config :logger, level: :warn

# Run acceptance test in concurrent mode
config :ehealth, sql_sandbox: true
