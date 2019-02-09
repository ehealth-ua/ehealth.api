defmodule GraphQLWeb.Resolvers.PersonResolver do
  @moduledoc false

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [render_error: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [response_to_ecto_struct: 2]

  alias Absinthe.Relay.Connection
  alias Core.Declarations.Declaration
  alias Core.Persons
  alias Core.Persons.Person
  alias GraphQLWeb.Loaders.OPS

  def list_persons(%{filter: filter, order_by: order_by} = args, _resolution) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         {:ok, persons} <- Persons.list(filter, order_by, {offset, limit + 1}) do
      opts = [has_previous_page: offset > 0, has_next_page: length(persons) > limit]
      persons = Enum.map(persons, &response_to_ecto_struct(Person, &1))

      Connection.from_slice(Enum.take(persons, limit), offset, opts)
    else
      err -> render_error(err)
    end
  end

  def get_person_by_id(_parent, %{id: id}, _resolution) do
    with {:ok, person} <- Persons.get_by_id(id) do
      {:ok, response_to_ecto_struct(Person, person)}
    else
      err -> render_error(err)
    end
  end

  def resolve_upcased(attr) do
    fn _, %{source: source} ->
      case Map.get(source, attr) do
        nil -> {:ok, nil}
        value -> {:ok, String.upcase(value)}
      end
    end
  end

  def load_declarations(parent, args, %{context: %{loader: loader}}) do
    batch_key = {:search_declarations, :many, :person_id, args}

    loader
    |> Dataloader.load(OPS, batch_key, parent)
    |> on_load(fn loader ->
      with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
           [_ | _] = declarations <- Dataloader.get(loader, OPS, batch_key, parent) do
        opts = [has_previous_page: offset > 0, has_next_page: length(declarations) > limit]
        declarations = Enum.map(declarations, &response_to_ecto_struct(Declaration, &1))

        Connection.from_slice(Enum.take(declarations, limit), offset, opts)
      else
        _ -> {:ok, %{edges: []}}
      end
    end)
  end

  def reset_authentication_method(%{person_id: id}, %{context: %{headers: headers}}) do
    with {:ok, person} <- Persons.reset_person_auth_method(id, headers) do
      {:ok, %{person: response_to_ecto_struct(Person, person)}}
    else
      err -> render_error(err)
    end
  end
end
