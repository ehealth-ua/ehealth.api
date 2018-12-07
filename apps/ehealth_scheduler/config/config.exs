use Mix.Config

config :ehealth_scheduler, EHealthScheduler.Worker,
  contract_requests_terminator_schedule: {:system, :string, "CONTRACT_REQUESTS_AUTO_TERMINATOR_SCHEDULE", "0 0-4 * * *"}

import_config "#{Mix.env()}.exs"
