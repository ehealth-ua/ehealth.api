use Mix.Config

config :swarm, node_blacklist: [~r/^.+$/]

config :ehealth_scheduler, EHealthScheduler.Worker,
  contract_requests_terminator_schedule:
    {:system, :string, "CONTRACT_REQUESTS_AUTO_TERMINATOR_SCHEDULE", "0 0,12 * * *"},
  medication_request_request_autotermination_schedule:
    {:system, :string, "MEDICATION_REQUEST_REQUEST_AUTOTERMINATION_SCHEDULE", "* * * * *"},
  declaration_request_autocleaning: {:system, :string, "DECLARATION_REQUEST_AUTOTCLEANING_SCHEDULE", "0 0-4 * * *"},
  declaration_request_autotermination:
    {:system, :string, "DECLARATION_REQUEST_AUTOTERMINATION_SCHEDULE", "0 0-4 * * *"},
  employee_request_autotermination: {:system, :string, "EMPLOYEE_REQUEST_AUTOTERMINATION_SCHEDULE", "0 0-4 * * *"},
  contract_autotermination: {:system, :string, "CONTRACT_AUTOTERMINATION_SCHEDULE", "0 0-4 * * *"},
  edr_validator_schedule: {:system, :string, "EDR_VALIDATOR_SCHEDULE", "0 0 * * *"},
  dls_validator_schedule: {:system, :string, "DLS_VALIDATOR_SCHEDULE", "0 0-4 * * *"},
  legal_entity_suspender_schedule: {:system, :string, "LEGAL_ENTITY_SUSPENDER_SCHEDULE", "0 0-4 * * *"},
  edr_synchronization_schedule: {:system, :string, "EDR_SYNCHRONIZATION_SCHEDULE", "0 0 * * *"}

config :ehealth_scheduler, EHealthScheduler.Jobs.ContractRequestsTerminator,
  contract_request_termination_batch_size: {:system, :integer, "CONTRACT_REQUEST_AUTOTERMINATION_BATCH_SIZE", 100}

config :ehealth_scheduler, EHealthScheduler.DeclarationRequests.Terminator,
  termination_batch_size: {:system, :integer, "DECLARATION_REQUEST_AUTOTERMINATION_BATCH", 10}

config :ehealth_scheduler, EHealthScheduler.Contracts.Terminator,
  termination_batch_size: {:system, :integer, "CONTRACT_AUTOTERMINATION_BATCH", 10}

config :ehealth_scheduler, EHealthScheduler.Jobs.LegalEntitySuspender,
  legal_entity_suspend_period_days: {:system, :integer, "LEGAL_ENTITY_SUSPEND_PERIOD_DAYS", 90}

import_config "#{Mix.env()}.exs"
