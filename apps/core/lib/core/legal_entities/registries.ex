defmodule Core.Registries do
  @moduledoc """
  The boundary for the Registries system.
  """

  import Ecto.{Query, Changeset}, warn: false

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Registry, as: UkrMedRegistry

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def count_registries_with_edrpou(edrpou, type) do
    @read_prm_repo.one(
      from(
        u in UkrMedRegistry,
        select: count("*"),
        where: u.edrpou == ^edrpou and u.type == ^type
      )
    )
  end

  def get_edrpou_verified_status(edrpou, type) do
    case count_registries_with_edrpou(edrpou, type) > 0 do
      true -> LegalEntity.mis_verified(:verified)
      _ -> LegalEntity.mis_verified(:not_verified)
    end
  end
end
