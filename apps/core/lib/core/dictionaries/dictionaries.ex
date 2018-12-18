defmodule Core.Dictionaries do
  @moduledoc """
  The boundary for the Dictionaries system.
  """

  import Ecto.{Query, Changeset}, warn: false

  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary
  alias Core.Dictionaries.DictionarySearch
  alias Core.Repo

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  @fields ~W(
    name
    values
    labels
    is_active
  )a

  @labels ~W(
    SYSTEM
    EXTERNAL
    ADMIN
    READ_ONLY
    TRANSLATIONS
  )

  def get_by_id(id), do: @read_repo.get(Dictionary, id)

  def fetch_by_id(id) do
    case get_by_id(id) do
      %Dictionary{} = dictionary -> {:ok, dictionary}
      nil -> {:error, {:not_found, "Dictionary not found"}}
    end
  end

  def list_dictionaries(attrs \\ %{}) do
    %DictionarySearch{}
    |> changeset_search(attrs)
    |> search_dictionaries()
  end

  defp search_dictionaries(%Ecto.Changeset{valid?: true, changes: changes}) when map_size(changes) > 0 do
    params = Map.to_list(changes)
    query = from(d in Dictionary, where: ^params)

    {:ok, @read_repo.all(query)}
  end

  defp search_dictionaries(%Ecto.Changeset{valid?: true}) do
    {:ok, @read_repo.all(Dictionary)}
  end

  defp search_dictionaries(%Ecto.Changeset{valid?: false} = changeset) do
    {:error, changeset}
  end

  def create_or_update_dictionary(name, attrs) do
    case get_dictionary(name) do
      %Dictionary{} = dict -> update_dictionary(dict, attrs)
      _ -> create_dictionary(attrs)
    end
  end

  def get_dictionary(name), do: @read_repo.get_by(Dictionary, name: name)

  def create_dictionary(attrs \\ %{}) do
    %Dictionary{}
    |> changeset_create(attrs)
    |> Repo.insert()
  end

  def update_dictionary(%Dictionary{} = dictionary, attrs) do
    dictionary
    |> changeset_update(attrs)
    |> Repo.update()
  end

  defp changeset_search(%DictionarySearch{} = dictionary, attrs) do
    fields = ~W(
      name
      is_active
    )a

    cast(dictionary, attrs, fields)
  end

  defp changeset_create(%Dictionary{} = dictionary, attrs) do
    dictionary
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_subset(:labels, @labels)
    |> validate_labels()
    |> validate_values()
  end

  defp changeset_update(%Dictionary{} = dictionary, attrs) do
    dictionary
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> validate_is_active(dictionary)
    |> validate_name()
    |> validate_subset(:labels, @labels)
    |> validate_labels()
    |> validate_values()
  end

  def get_dictionary_value(value, dictionary_name) do
    {:ok, dictionaries} = Dictionaries.list_dictionaries(%{name: dictionary_name})

    dictionaries
    |> Enum.at(0)
    |> fetch_dictionary_value(value)
  end

  defp fetch_dictionary_value(%Dictionary{values: values}, value), do: Map.get(values, value)
  defp fetch_dictionary_value(_, _value), do: nil

  def get_dictionaries(dictionary_list) do
    query = from(d in Dictionary, where: d.name in ^dictionary_list and d.is_active, select: {d.name, d.values})

    query
    |> @read_repo.all()
    |> Map.new()
  end

  def get_dictionaries_keys(dictionary_list) do
    dictionary_list
    |> get_dictionaries()
    |> Enum.reduce(%{}, fn {d_name, d_values}, acc -> Map.put(acc, d_name, Map.keys(d_values)) end)
  end

  defp validate_name(changeset) do
    validate_change(changeset, :name, fn :name, _ -> [name: "Name can't be changed"] end)
  end

  defp validate_is_active(changeset, %Dictionary{is_active: false}) do
    add_error(changeset, :is_active, "Deactivated dictionary is not allowed to be updated")
  end

  defp validate_is_active(changeset, _) do
    validate_change(changeset, :is_active, fn _, _ -> [is_active: "Dictionary is not allowed to be deactivated"] end)
  end

  defp validate_labels(changeset) do
    case fetch_field(changeset, :labels) do
      {:changes, labels} ->
        if labels != Enum.uniq(labels) do
          add_error(changeset, :labels, "Labels are duplicated")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  defp validate_values(changeset) do
    case fetch_field(changeset, :values) do
      {:changes, value} when value == %{} -> add_error(changeset, :values, "Values should not be empty")
      _ -> changeset
    end
  end
end
