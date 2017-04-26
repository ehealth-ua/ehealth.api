use Mix.Config

# General application configuration
# Configures the endpoint
config :ehealth, EHealth.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "AcugHtFljaEFhBY1d6opAasbdFYsvV8oydwW98qS0oZOv+N/a5TE5G7DPfTZcXm9",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

# Configures Digital Signature API
config :ehealth, EHealth.API.Signature,
  endpoint: {:system, "DIGITAL_SIGNATURE_ENDPOINT", "http://52.58.60.8:8083/DigitalSignatureService.svc"}

# Configures MediaStorage API
config :ehealth, EHealth.API.MediaStorage,
  endpoint: {:system, "MEDIA_STORAGE_ENDPOINT", ""}

# Configures PRM API
config :ehealth, EHealth.API.PRM,
  endpoint: {:system, "PRM_ENDPOINT", ""}

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure JSON Logger back-end
config :logger_json, :backend,
  on_init: {EHealth, :load_from_system_env, []},
  json_encoder: Poison,
  metadata: :all

import_config "#{Mix.env}.exs"
