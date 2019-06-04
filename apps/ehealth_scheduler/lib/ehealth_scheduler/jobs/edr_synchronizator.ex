defmodule EHealthScheduler.Jobs.EdrSynchronizator do
  @moduledoc false

  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Jobs.EdrSynchronizationJob
  import Ecto.Query
  require Logger

  def run do
    LegalEntity
    |> where([le], is_nil(le.edr_data_id))
    |> PRMRepo.all()
    |> Enum.each(fn legal_entity ->
      case EdrSynchronizationJob.create(legal_entity) do
        {:ok, %{}} ->
          :ok

        err ->
          Logger.error("Failed to create EdrSynchronizationJob. Reason: #{err}")
          err
      end
    end)
  end
end
