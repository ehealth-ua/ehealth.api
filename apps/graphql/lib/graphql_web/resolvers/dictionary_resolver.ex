defmodule GraphQLWeb.Resolvers.DictionaryResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors
  import GraphQLWeb.Resolvers.Helpers.Search, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary
  alias Core.Repo

  def list_dictionaries(%{filter: filter} = args, _resolution) do
    filter = prepare_filter(filter)

    Dictionary
    |> filter(filter)
    |> Connection.from_query(&Repo.all/1, args)
  end

  defp prepare_filter([]), do: []

  defp prepare_filter([{:label, value} | tail]) do
    [{:label, {:fragment, {:contain, :labels, [value]}}} | prepare_filter(tail)]
  end

  defp prepare_filter([{:name, value} | tail]) do
    [{:name, {:like, value}} | prepare_filter(tail)]
  end

  defp prepare_filter([head | tail]), do: [head | prepare_filter(tail)]

  def update(%{id: id} = args, _resolution) do
    with {:ok, dictionary} <- Dictionaries.fetch_by_id(id),
         {:ok, dictionary} <- Dictionaries.update_dictionary(dictionary, args) do
      {:ok, %{dictionary: dictionary}}
    else
      # ToDo: Here should be generic way to handle errors. E.g as FallbackController in Phoenix
      # Should be implemented with task https://github.com/edenlabllc/ehealth.web/issues/423
      {:error, {:not_found, error}} ->
        {:error, format_not_found_error(error)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_unprocessable_entity_error(changeset)}
    end
  end
end
