use Mix.Config

config :ehealth_scheduler, EHealthScheduler.Worker,
  contract_requests_terminator_schedule:
    {:system, :string, "CONTRACT_REQUESTS_AUTO_TERMINATOR_SCHEDULE", "0 0,12 * * *"}

config :ehealth_scheduler, EHealthScheduler.Jobs.ContractRequestsTerminator,
  contract_request_termination_batch_size: {:system, :integer, "CONTRACT_REQUEST_AUTOTERMINATION_BATCH_SIZE", 100}

import_config "#{Mix.env()}.exs"
