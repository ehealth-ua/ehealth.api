use Mix.Config

# General application configuration
config :ehealth,
  env: Mix.env(),
  namespace: EHealth,
  run_declaration_request_terminator: true,
  sensitive_data_in_response: {:system, :boolean, "SENSITIVE_DATA_IN_RESPONSE_ENABLED", false}

# Config Jason as default Json encoder for Phoenix
config :phoenix, :format_encoders, json: Jason

# Configures the endpoint
config :ehealth, EHealth.Web.Endpoint,
  url: [
    host: "localhost"
  ],
  secret_key_base: "AcugHtFljaEFhBY1d6opAasbdFYsvV8oydwW98qS0oZOv+N/a5TE5G7DPfTZcXm9",
  render_errors: [
    view: EView.Views.PhoenixError,
    accepts: ~w(json)
  ]

config :ehealth, EHealth.Scheduler,
  declaration_request_autotermination:
    {:system, :string, "DECLARATION_REQUEST_AUTOTERMINATION_SCHEDULE", "* 0-4 * * *"},
  employee_request_autotermination: {:system, :string, "EMPLOYEE_REQUEST_AUTOTERMINATION_SCHEDULE", "0-4 * * *"},
  contract_autotermination: {:system, :string, "CONTRACT_AUTOTERMINATION_SCHEDULE", "0-4 * * *"}

config :ehealth, EHealth.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 10}

config :ehealth, EHealth.Contracts.Terminator,
  termination_batch_size: {:system, :integer, "CONTRACT_AUTOTERMINATION_BATCH", 10}

import_config "#{Mix.env()}.exs"
