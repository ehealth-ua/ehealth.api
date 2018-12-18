defmodule GraphQLWeb.Resolvers.DictionaryResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]
  import GraphQLWeb.Resolvers.Helpers.Search, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary

  @read_repo Application.get_env(:core, :repos)[:read_repo]

  def list_dictionaries(%{filter: filter} = args, _resolution) do
    filter = prepare_filter(filter)

    Dictionary
    |> filter(filter)
    |> Connection.from_query(&@read_repo.all/1, args)
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
      err -> render_error(err)
    end
  end
end
