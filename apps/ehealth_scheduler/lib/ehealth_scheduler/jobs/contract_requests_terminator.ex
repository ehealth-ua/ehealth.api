defmodule EHealthScheduler.Jobs.ContractRequestsTerminator do
  @moduledoc false

  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Repo
  alias Ecto.Multi
  import Ecto.Query
  require Logger

  def run do
    Logger.info("terminate all contract requests with start_date <= today()")

    query =
      CapitationContractRequest
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

    author_id = Confex.fetch_env!(:core, :system_user)

    new_status = CapitationContractRequest.status(:terminated)

    updates = [
      status: new_status,
      status_reason: "auto_expired",
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
end
