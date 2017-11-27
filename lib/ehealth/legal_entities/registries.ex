defmodule EHealth.Registries do
  @moduledoc """
  The boundary for the Registries system.
  """

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo, as: Repo
  alias EHealth.LegalEntities.Registry, as: UkrMedRegistry
  alias EHealth.LegalEntities.LegalEntity

  def count_registries_with_edrpou(edrpou, type) do
    Repo.one(
      from u in UkrMedRegistry,
      select: count("*"),
      where: u.edrpou == ^edrpou and u.type == ^type
    )
  end

  def get_edrpou_verified_status(edrpou, type) do
    case count_registries_with_edrpou(edrpou, type) > 0 do
      true -> LegalEntity.mis_verified(:verified)
      _    -> LegalEntity.mis_verified(:not_verified)
    end
  end
end
