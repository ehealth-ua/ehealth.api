defmodule EHealth.Scheduler do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :ehealth

  alias Crontab.CronExpression.Parser
  alias Quantum.Job
  alias Quantum.RunStrategy.Local
  import EHealth.DeclarationRequests.Terminator, only: [terminate_declaration_requests: 0]
  import Core.EmployeeRequests, only: [terminate_employee_requests: 0]
  import EHealth.Contracts.Terminator, only: [terminate_contracts: 0]

  def create_jobs do
    __MODULE__.new_job()
    |> Job.set_name(:declaration_request_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:declaration_request_autotermination]))
    |> Job.set_task(&terminate_declaration_requests/0)
    |> Job.set_run_strategy(Local)
    |> __MODULE__.add_job()

    __MODULE__.new_job()
    |> Job.set_name(:employee_request_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:employee_request_autotermination]))
    |> Job.set_task(&terminate_employee_requests/0)
    |> Job.set_run_strategy(Local)
    |> __MODULE__.add_job()

    __MODULE__.new_job()
    |> Job.set_name(:contract_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:contract_autotermination]))
    |> Job.set_task(&terminate_contracts/0)
    |> Job.set_run_strategy(Local)
    |> __MODULE__.add_job()
  end

  defp get_config do
    Confex.fetch_env!(:ehealth, __MODULE__)
  end
end
