use Mix.Config

config :ehealth_scheduler, EHealthScheduler.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 1}

config :ehealth_scheduler, EHealthScheduler.Contracts.Terminator, termination_batch_size: 1

config :ehealth_scheduler, EHealthScheduler.Jobs.LegalEntitySuspender,
  legal_entity_suspend_period_days: {:system, :integer, "LEGAL_ENTITY_SUSPEND_PERIOD_DAYS", 10}

# Print only warnings and errors during test
config :logger, level: :warn
