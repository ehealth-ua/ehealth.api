defmodule EHealthScheduler.Jobs.ContractRequestsTerminator do
  @moduledoc false

  use Confex, otp_app: :ehealth_scheduler
  import Ecto.Query
  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Repo
  alias Ecto.Multi
  require Logger

  def run do
    config()
    |> get_in([:contract_request_termination_batch_size])
    |> chunk_terminate()
  end

  defp terminate_contract_requests(limit) do
    Logger.info("terminate all contract requests with start_date <= today()")

    contract_request_ids =
      CapitationContractRequest
      |> select([cr], cr.id)
      |> where(
        [cr],
        cr.status in ^[
          CapitationContractRequest.status(:new),
          CapitationContractRequest.status(:in_process),
          CapitationContractRequest.status(:approved),
          CapitationContractRequest.status(:nhs_signed),
          CapitationContractRequest.status(:pending_nhs_sign)
        ]
      )
      |> where([cr], cr.start_date <= ^Date.utc_today())
      |> limit([cr], ^limit)
      |> Repo.all()

    query =
      CapitationContractRequest
      |> where(
        [cr],
        cr.id in ^contract_request_ids
      )

    author_id = Confex.fetch_env!(:core, :system_user)

    new_status = CapitationContractRequest.status(:terminated)

    updates = [
      status: new_status,
      status_reason: "AUTO_EXPIRED",
      updated_by: author_id,
      updated_at: DateTime.utc_now()
    ]

    Multi.new()
    |> Multi.update_all(:contract_requests, query, [set: updates],
      returning: [:id, :status, :status_reason, :updated_by]
    )
    |> Multi.run(:insert_events, &ContractRequests.insert_events(&1, new_status, author_id))
    |> Repo.transaction()
  end

  defp chunk_terminate(limit) do
    case terminate_contract_requests(limit) do
      {:ok, %{contract_requests: {0, _}}} -> :ok
      {:ok, %{contract_requests: _}} -> chunk_terminate(limit)
    end
  end
end
