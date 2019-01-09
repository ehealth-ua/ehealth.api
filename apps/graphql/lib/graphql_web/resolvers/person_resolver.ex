defmodule GraphQLWeb.Resolvers.PersonResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]
  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]

  alias Absinthe.Relay.Connection
  alias Core.Persons

  def list_persons(%{filter: filter, order_by: order_by} = args, _resolution) do
    with {:ok, search_params} <- prepare_search_params(filter),
         {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         {:ok, persons} <- Persons.list(search_params, order_by, {offset, limit + 1}) do
      opts = [has_previous_page: offset > 0, has_next_page: length(persons) > limit]

      Connection.from_slice(Enum.take(persons, limit), offset, opts)
    else
      {:error, :empty_filter} -> {:ok, %{edges: []}}
      err -> render_error(err)
    end
  end

  def get_person_by_id(_parent, %{id: id}, _resolution) do
    with {:ok, person} <- Persons.get_by_id(id) do
      {:ok, person}
    else
      err -> render_error(err)
    end
  end

  def resolve_upcased(attr) when is_atom(attr) do
    fn _, %{source: source} ->
      case Map.get(source, attr) do
        nil -> {:ok, nil}
        value -> {:ok, String.upcase(value)}
      end
    end
  end

  defp prepare_search_params(%{} = params) do
    params
    |> atoms_to_strings()
    |> do_prepare_params()
    |> case do
      {:ok, _search_params} = result -> result
      _ -> {:error, :empty_filter}
    end
  end

  defp do_prepare_params(%{"personal" => params}) when params == %{}, do: :error
  defp do_prepare_params(%{"documents" => params}) when params == %{}, do: :error

  defp do_prepare_params(%{"personal" => personal_params, "documents" => documents_params}) do
    personal_params =
      %{}
      |> put_optional_param(personal_params["birth_date"], "birth_date")
      |> put_optional_param(personal_params["authentication_method"]["phone_number"], "auth_phone_number")

    documents_params =
      %{}
      |> put_optional_param(documents_params["tax_id"], "tax_id")
      |> prepare_document_number(documents_params["number"])

    {:ok, Map.merge(personal_params, documents_params)}
  end

  defp put_optional_param(search_params, nil, _key), do: search_params
  defp put_optional_param(search_params, value, key), do: Map.put(search_params, key, value)

  defp prepare_document_number(search_params, nil), do: search_params

  defp prepare_document_number(search_params, number) do
    Map.merge(search_params, %{"documents" => [%{"type" => "PASSPORT", "number" => number}]})
  end
end
