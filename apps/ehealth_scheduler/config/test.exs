use Mix.Config

config :ehealth_scheduler, EHealthScheduler.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 1}

config :ehealth_scheduler, EHealthScheduler.Contracts.Terminator, termination_batch_size: 1

# Print only warnings and errors during test
config :logger, level: :warn
