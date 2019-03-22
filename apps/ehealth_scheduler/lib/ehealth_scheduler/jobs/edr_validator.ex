defmodule EHealthScheduler.Jobs.EdrValidator do
  @moduledoc """
  Publish kafka events to validate legal entities by EDR service
  """

  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  import Ecto.Query

  @producer Application.get_env(:core, :kafka)[:producer]

  def run do
    LegalEntity
    |> select([le], [:id])
    |> where([le], le.status == ^LegalEntity.status(:active) and le.is_active)
    |> PRMRepo.all()
    |> Enum.each(fn %{id: id} ->
      :ok = @producer.publish_verify_legal_entity(%{"legal_entity_id" => id})
    end)
  end
end
