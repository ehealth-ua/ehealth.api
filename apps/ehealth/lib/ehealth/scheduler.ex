defmodule EHealth.Scheduler do
  @moduledoc false

  use Quantum.Scheduler, otp_app: :ehealth

  alias Crontab.CronExpression.Parser
  alias Quantum.Job
  import EHealth.DeclarationRequests.Terminator, only: [terminate_declaration_requests: 1]
  import EHealth.EmployeeRequests, only: [terminate_employee_requests: 0]

  def create_jobs do
    __MODULE__.new_job()
    |> Job.set_name(:declaration_request_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:declaration_request_autotermination]))
    |> Job.set_task(fn -> terminate_declaration_requests(self()) end)
    |> __MODULE__.add_job()

    __MODULE__.new_job()
    |> Job.set_name(:employee_request_autotermination)
    |> Job.set_overlap(false)
    |> Job.set_schedule(Parser.parse!(get_config()[:employee_request_autotermination]))
    |> Job.set_task(&terminate_employee_requests/0)
    |> __MODULE__.add_job()
  end

  defp get_config do
    Confex.fetch_env!(:ehealth, __MODULE__)
  end
end
