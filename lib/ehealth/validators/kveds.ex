defmodule EHealth.Validators.KVEDs do
  @moduledoc """
  KVED codes validator
  """

  import Ecto.Changeset

  alias EHealth.Dictionaries
  alias EHealth.Dictionaries.Dictionary
  alias EHealth.LegalEntities.LegalEntity

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)

  @kveds_allowed "KVEDS"
  @kveds_msp_required "KVEDS_ALLOWED_MSP"
  @kveds_pharmacy_required "KVEDS_ALLOWED_PHARMACY"

  def validate(kveds, type \\ @msp) do
    data  = %{}
    types = %{kveds: {:array, :string}}

    {data, types}
    |> cast(%{"kveds" => kveds}, Map.keys(types))
    |> validate_required_kveds(get_required_kveds(type))
    |> validate_allowed_kveds(get_allowed_kveds())
  end

  def validate_required_kveds(%Ecto.Changeset{} = changeset, kveds) when length(kveds) > 0 do
    changeset
    |> get_field(:kveds, [])
    |> MapSet.new()
    |> MapSet.intersection(MapSet.new(kveds))
    |> MapSet.size()
    |> case do
         0 -> add_error(changeset, :kveds, "At least one KVED code must be from list #{inspect kveds}")
         _ -> changeset
       end
  end
  def validate_required_kveds(changeset, _kveds), do: changeset

  def validate_allowed_kveds(%Ecto.Changeset{} = changeset, kveds) when length(kveds) > 0 do
    validate_subset(changeset, :kveds, kveds)
  end

  def validate_allowed_kveds(changeset, _kveds), do: changeset

  def get_allowed_kveds do
    @kveds_allowed
    |> Dictionaries.get_dictionary()
    |> get_dictionary_kveds()
  end

  defp get_required_kveds(@msp) do
    do_get_required_kveds(@kveds_msp_required)
  end
  defp get_required_kveds(@pharmacy) do
    do_get_required_kveds(@kveds_pharmacy_required)
  end

  defp do_get_required_kveds(name) do
    name
    |> Dictionaries.get_dictionary()
    |> get_dictionary_kveds()
  end

  def get_dictionary_kveds(%Dictionary{values: values}) do
    Map.keys(values)
  end
  def get_dictionary_kveds(_), do: []
end
