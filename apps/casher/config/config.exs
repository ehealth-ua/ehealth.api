use Mix.Config

config :logger, :console,
  format: "$message\n",
  handle_otp_reports: true,
  level: :info

config :casher,
  cache_ttl: [
    person_data: {:system, :integer, "PERSON_DATA_TTL", _15_min = 15 * 60}
  ]

import_config "#{Mix.env()}.exs"
