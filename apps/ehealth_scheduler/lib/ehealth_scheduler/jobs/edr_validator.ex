defmodule EHealthScheduler.Jobs.EdrValidator do
  @moduledoc """
  Publish kafka events to validate legal entities by EDR service
  """

  alias Core.LegalEntities.EdrData
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  import Ecto.Query

  @producer Application.get_env(:core, :kafka)[:producer]

  def run do
    EdrData
    |> select([ed], [:id])
    |> distinct([ed], ed.id)
    |> join(:left, [ed], l in assoc(ed, :legal_entities))
    |> where(
      [ed, le],
      le.status in ^[LegalEntity.status(:active), LegalEntity.status(:suspended), LegalEntity.status(:reorganized)] and
        le.is_active
    )
    |> PRMRepo.all()
    |> Enum.each(fn %{id: id} ->
      :ok = @producer.publish_sync_edr_data(%{"id" => id})
    end)
  end
end
