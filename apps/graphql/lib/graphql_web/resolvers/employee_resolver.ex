defmodule GraphQLWeb.Resolvers.EmployeeResolver do
  @moduledoc false

  import Ecto.Query, only: [join: 4, where: 3, order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.Employees.Employee
  alias GraphQL.Helpers.Filtering

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_employees(args, %{context: %{client_type: "NHS"}}), do: list_employees(args)

  def list_employees(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:legal_entity_id, :equal, client_id} | &1])
    |> list_employees()
  end

  def list_employees(%{filter: filter, order_by: order_by} = args) do
    Employee
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  defp filter(query, []), do: query

  # NOTE: This filter function will work while party assoc filter has only one field
  defp filter(query, [{:party, nil, [{:full_name, :full_text_search, value}]} | tail]) do
    query
    |> filter(tail)
    |> join(:inner, [e], p in assoc(e, :party))
    |> where(
      [..., p],
      fragment(
        "to_tsvector(concat_ws(' ', ?, ?, ?)) @@ plainto_tsquery(?)",
        p.last_name,
        p.first_name,
        p.second_name,
        ^value
      )
    )
  end

  # BUG: When association condition goes before regular conditions,
  # all following conditions will be applied to the associated table
  defp filter(query, [condition | tail]) do
    query
    |> Filtering.filter([condition])
    |> filter(tail)
  end
end
