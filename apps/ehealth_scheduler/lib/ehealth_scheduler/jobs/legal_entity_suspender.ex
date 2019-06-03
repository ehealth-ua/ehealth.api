defmodule EHealthScheduler.Jobs.LegalEntitySuspender do
  @moduledoc """
  Suspend legal entities and related contracts when legal entity's nhs_verified flag was set to false > 90 days ago
  """

  use Confex, otp_app: :ehealth_scheduler

  alias Core.Contracts.ContractSuspender
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  import Ecto.Query

  def run do
    today = Date.utc_today()
    suspend_period_days = config()[:legal_entity_suspend_period_days]

    legal_entity_ids =
      LegalEntity
      |> select([le], %{id: le.id})
      |> where([le], le.status == ^LegalEntity.status(:active))
      |> where(
        [le],
        fragment("(?)::date < (?)", le.nhs_unverified_at, date_add(^today, -1 * ^suspend_period_days, "day"))
      )
      |> PRMRepo.all()
      |> Enum.map(& &1.id)

    PRMRepo.transaction(fn ->
      LegalEntity
      |> where([le], le.id in ^legal_entity_ids)
      |> PRMRepo.update_all(
        set: [
          status: LegalEntity.status(:suspended),
          status_reason: "AUTO_SUSPEND"
        ]
      )

      suspend_contracts(legal_entity_ids)
    end)
  end

  defp suspend_contracts(ids) do
    Enum.each(ids, fn id ->
      ContractSuspender.suspend_by_contractor_legal_entity_id(id)
    end)
  end
end
