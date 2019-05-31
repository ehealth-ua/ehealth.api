defmodule Jobs.ContractRequestTerminationJob do
  @moduledoc false

  use Confex, otp_app: :core
  alias Core.ContractRequests
  alias Jobs.Jabba.Client, as: JabbaClient
  alias Jobs.Jabba.Task, as: JabbaTask
  require Logger

  @contract_request_terminate_task_type JabbaTask.type(:contract_request_terminate)
  @contract_request_termination_job_type JabbaClient.type(:contract_request_termination)

  def search_jobs(filter, order_by, limit, offset) do
    filter
    |> Kernel.++([{:type, :equal, @contract_request_termination_job_type}])
    |> JabbaClient.search_jobs(order_by, {offset, limit})
  end

  def get_job(id) do
    case JabbaClient.get_job(id) do
      {:ok, job} -> {:ok, job}
      nil -> {:ok, nil}
    end
  end

  def terminate(contract_request, actor_id) do
    ContractRequests.do_terminate(actor_id, contract_request, %{"status_reason" => "auto_suspend_legal_entity"})
  rescue
    e ->
      Logger.error("Failed to terminate contract request with: #{inspect(e)}")
      {:error, e}
  end

  def create(contract_request, actor_id) do
    task = JabbaTask.new(@contract_request_terminate_task_type, contract_request, actor_id)
    JabbaClient.create_job([task], @contract_request_termination_job_type, name: "Terminate contract request")
  end
end
