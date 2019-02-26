defmodule Core.Validators.V2.KVEDs do
  @moduledoc """
  KVED codes validator
  """

  import Ecto.Changeset

  alias Core.Dictionaries
  alias Core.LegalEntities.LegalEntity
  alias Core.Validators.KVEDs, as: V1KVEDs

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)
  @msp_pharmacy LegalEntity.type(:msp_pharmacy)

  @kveds_msp_required "KVEDS_ALLOWED_MSP"
  @kveds_pharmacy_required "KVEDS_ALLOWED_PHARMACY"

  def validate(kveds), do: validate(kveds, @msp)

  def validate(kveds, @msp_pharmacy) do
    data = %{}
    types = %{kveds: {:array, :string}}

    {data, types}
    |> cast(%{"kveds" => kveds}, Map.keys(types))
    |> validate_required_kveds(get_required_kveds(@pharmacy))
    |> validate_required_kveds(get_required_kveds(@msp))
    |> validate_allowed_kveds(get_allowed_kveds())
  end

  def validate(kveds, type) do
    data = %{}
    types = %{kveds: {:array, :string}}

    {data, types}
    |> cast(%{"kveds" => kveds}, Map.keys(types))
    |> validate_required_kveds(get_required_kveds(type))
    |> validate_allowed_kveds(get_allowed_kveds())
  end

  defp get_required_kveds(@msp) do
    do_get_required_kveds(@kveds_msp_required)
  end

  defp get_required_kveds(@pharmacy) do
    do_get_required_kveds(@kveds_pharmacy_required)
  end

  defp get_required_kveds(@msp_pharmacy) do
    do_get_required_kveds(@kveds_msp_required) ++
      do_get_required_kveds(@kveds_pharmacy_required)
  end

  defp do_get_required_kveds(name) do
    name
    |> Dictionaries.get_dictionary()
    |> get_dictionary_kveds()
  end

  defdelegate validate_required_kveds(changeset, kveds), to: V1KVEDs
  defdelegate validate_allowed_kveds(changeset, kveds), to: V1KVEDs
  defdelegate get_allowed_kveds, to: V1KVEDs
  defdelegate get_dictionary_kveds(dictionary), to: V1KVEDs
end
