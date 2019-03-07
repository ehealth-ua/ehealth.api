defmodule GraphQLWeb.Resolvers.EmployeeResolver do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Employees.Employee

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
end
