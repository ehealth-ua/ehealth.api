defmodule EHealth.PRM.Registries do
  @moduledoc """
  The boundary for the Registries system.
  """

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.PRMRepo, as: Repo
  alias EHealth.PRM.Registries.Schema, as: UkrMedRegistry

  def count_registries_with_edrpou(edrpou) do
    Repo.one(
      from u in UkrMedRegistry,
      select: count("*"),
      where: u.edrpou == ^edrpou
    )
  end

  def get_edrpou_verified_status(edrpou) do
    case count_registries_with_edrpou(edrpou) > 0 do
      true -> "VERIFIED"
      _    -> "NOT_VERIFIED"
    end
  end

end
