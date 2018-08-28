use Mix.Config

config :casher,
  redis_pool_size: {:system, :integer, "REDIS_POOL_SIZE", 5}

config :casher, Casher.Web.Endpoint,
  load_from_system_env: true,
  url: [host: "localhost"],
  secret_key_base: "uu+Txi5foz03+47+ynb3nJpiIpHEZ1AhT17vW5j59qO8MoIfLXVtOutJTddI8zTE",
  render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]

config :phoenix, :format_encoders, json: Jason

config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :casher,
  cache_ttl: [
    person_data: {:system, :integer, "PERSON_DATA_TTL", _15_min = 15 * 60}
  ]

import_config "#{Mix.env()}.exs"
