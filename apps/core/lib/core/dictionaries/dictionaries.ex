defmodule Core.Dictionaries do
  @moduledoc """
  The boundary for the Dictionaries system.
  """

  use Confex, otp_app: :core

  import Ecto.{Query, Changeset}, warn: false

  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary
  alias Core.Dictionaries.DictionarySearch
  alias Core.Repo

  require Logger

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

  def fetch_or_fail(name) do
    case get_dictionary(name) do
      %Dictionary{} = dictionary ->
        {:ok, dictionary}

      _ ->
        Logger.error("Dictionary with name: #{inspect(name)} not found")
        {:error, {:internal_server_error, "Dictionary error"}}
    end
  end

  def list_dictionaries(attrs \\ %{}) do
    %DictionarySearch{}
    |> changeset_search(attrs)
    |> search_dictionaries()
  end

  defp search_dictionaries(%Ecto.Changeset{valid?: true, changes: changes}) when map_size(changes) > 0 do
    query =
      Dictionary
      |> query_by(:is_active, changes[:is_active])
      |> query_by(:name, changes[:name])

    query =
      if Map.has_key?(changes, :name) do
        query
      else
        query_without_big_dictionaries(query)
      end

    {:ok, @read_repo.all(query)}
  end

  defp search_dictionaries(%Ecto.Changeset{valid?: true}) do
    query = query_without_big_dictionaries(Dictionary)

    {:ok, @read_repo.all(query)}
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

  defp query_by(query, _, nil), do: query

  defp query_by(query, :name, name) do
    if String.contains?(name, ",") do
      names =
        name
        |> String.split(",")
        |> Enum.reject(&(String.trim(&1) == ""))
        |> Enum.uniq()

      where(query, [d], d.name in ^names)
    else
      where(query, [d], d.name == ^name)
    end
  end

  defp query_by(query, key, value), do: where(query, [d], field(d, ^key) == ^value)

  def query_without_big_dictionaries(query) do
    big_dictionaries = config()[:big_dictionaries]

    where(query, [d], d.name not in ^big_dictionaries)
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
