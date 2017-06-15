defmodule EHealth.LegalEntity.ValidatorKVEDs do
  @moduledoc """
  KVED codes validator
  """

  import Ecto.Changeset

  alias EHealth.Dictionaries
  alias EHealth.Dictionaries.Dictionary

  @kveds_dictionary_name "KVEDS"

  def validate(kveds) do
    data  = %{}
    types = %{kveds: {:array, :string}}

    {data, types}
    |> cast(%{"kveds" => kveds}, Map.keys(types))
    |> validate_kveds(get_allowed_kveds())
  end

  def validate_kveds(%Ecto.Changeset{} = changeset, kveds) when length(kveds) > 0 do
    validate_subset(changeset, :kveds, kveds)
  end

  def validate_kveds(changeset, _kveds), do: changeset

  def get_allowed_kveds do
    @kveds_dictionary_name
    |> Dictionaries.get_dictionary()
    |> get_dictionary_kveds()
  end

  def get_dictionary_kveds(%Dictionary{values: values}) do
    Map.keys(values)
  end

  def get_dictionary_kveds(_), do: []

end
