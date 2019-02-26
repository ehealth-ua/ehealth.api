defmodule Core.V2.Registries do
  @moduledoc """
  The boundary for the Registries system.
  """

  alias Core.LegalEntities.LegalEntity
  alias Core.Registries

  def get_edrpou_verified_status(edrpou, legal_entity_type) do
    types = String.split(legal_entity_type, "_")

    types
    |> Enum.reduce_while(:not_verified, fn type, _ ->
      if count_registries_with_edrpou(edrpou, type) > 0, do: {:cont, :verified}, else: {:halt, :not_verified}
    end)
    |> LegalEntity.mis_verified()
  end

  defdelegate count_registries_with_edrpou(edrpou, type), to: Registries
end
