defmodule GraphQL.Resolvers.Employee do
  @moduledoc false

  import Ecto.Query, only: [join: 4, order_by: 3]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Employees.Employee
  alias Ecto.Query

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
    |> order_by(order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  defp order_by(query, [{direction, :party_full_name}]) do
    query
    |> join(:left, [r], assoc(r, :party))
    |> order_by([..., a], [{^direction, a.last_name}, {^direction, a.first_name}, {^direction, a.second_name}])
  end

  defp order_by(query, [{direction, :legal_entity_name}]) do
    query
    |> join(:left, [r], assoc(r, :legal_entity))
    |> order_by([..., a], [{^direction, a.name}])
  end

  defp order_by(query, [{direction, :division_name}]) do
    query
    |> join(:left, [r], assoc(r, :division))
    |> order_by([..., a], [{^direction, a.name}])
  end

  defp order_by(query, expr), do: Query.order_by(query, ^expr)
end
