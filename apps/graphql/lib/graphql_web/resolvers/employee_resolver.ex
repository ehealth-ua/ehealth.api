defmodule GraphQLWeb.Resolvers.EmployeeResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Search, only: [search: 2]

  alias Absinthe.Relay.Connection
  alias Core.Employees.Employee
  alias Core.PRMRepo

  def list_employees(args, %{context: %{client_type: "NHS"}}), do: list_employees(args)

  def list_employees(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    args
    |> Map.update!(:filter, &[{:legal_entity_id, client_id} | &1])
    |> list_employees()
  end

  def list_employees(args) do
    Employee
    |> search(args)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end
end
