defmodule EHealthScheduler.Worker do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :ehealth_scheduler

  alias Core.DLS
  alias Core.EmployeeRequests
  alias Core.MedicationRequestRequests
  alias Crontab.CronExpression.Parser
  alias EHealthScheduler.Contracts.Terminator, as: ContractsTerminator
  alias EHealthScheduler.DeclarationRequests.Terminator, as: DeclarationRequestsTerminator
  # alias EHealthScheduler.Jobs.ContractRequestsTerminator
  alias EHealthScheduler.Jobs.EdrSynchronizator
  alias EHealthScheduler.Jobs.EdrValidator
  alias EHealthScheduler.Jobs.LegalEntitySuspender
  alias Quantum.Job
  alias Quantum.RunStrategy.Local

  defp create_job(fun, config_name) do
    config = Confex.fetch_env!(:ehealth_scheduler, __MODULE__)

    __MODULE__.new_job()
    |> Job.set_name(config_name)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(config[config_name]))
    |> Job.set_task(fun)
    |> Job.set_run_strategy(%Local{})
    |> __MODULE__.add_job()
  end

  def create_jobs do
    # create_job(&ContractRequestsTerminator.run/0, :contract_requests_terminator_schedule)

    create_job(
      &DeclarationRequestsTerminator.clean_declaration_requests/0,
      :declaration_request_autocleaning
    )

    create_job(
      &DeclarationRequestsTerminator.terminate_declaration_requests/0,
      :declaration_request_autotermination
    )

    create_job(
      &ContractsTerminator.terminate_contracts/0,
      :contract_autotermination
    )

    create_job(
      &EmployeeRequests.terminate_employee_requests/0,
      :employee_request_autotermination
    )

    create_job(
      &MedicationRequestRequests.autoterminate/0,
      :medication_request_request_autotermination_schedule
    )

    create_job(
      &EdrValidator.run/0,
      :edr_validator_schedule
    )

    create_job(&DLS.validate_divisions/0, :dls_validator_schedule)
    create_job(&LegalEntitySuspender.run/0, :legal_entity_suspender_schedule)
    create_job(&EdrSynchronizator.run/0, :edr_synchronization_schedule)
  end
end
