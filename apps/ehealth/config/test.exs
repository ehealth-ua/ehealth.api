use Mix.Config

# Configuration for test environment
config :ex_unit, capture_log: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ehealth, EHealth.Web.Endpoint,
  http: [port: 4001],
  server: true

config :ehealth,
  sensitive_data_in_response: {:system, :boolean, "SENSITIVE_DATA_IN_RESPONSE_ENABLED", true}

# Configures declaration request terminator
config :ehealth, EHealth.DeclarationRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

# Configures employee request terminator
config :ehealth, EHealth.EmployeeRequest.Terminator,
  frequency: 100,
  utc_interval: {0, 23}

config :ehealth, EHealth.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 1}

config :ehealth, EHealth.Contracts.Terminator, termination_batch_size: 1

config :ehealth,
  # Run acceptance test in concurrent mode
  sql_sandbox: true,
  # Don't start terminator in test env
  run_declaration_request_terminator: false
