defmodule GraphQLWeb.Loaders.PRM do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2, limit: 2, offset: 2]

  alias Absinthe.Relay.Connection
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees.Employee
  alias Core.PRMRepo
  alias GraphQLWeb.Resolvers.Helpers.Search

  def data, do: Dataloader.Ecto.new(PRMRepo, query: &query/2)

  def query(CapitationContract, %{client_type: "MSP", client_id: client_id}) do
    where(CapitationContract, contractor_legal_entity_id: ^client_id)
  end

  def query(ReimbursementContract, %{client_type: "PHARMACY", client_id: client_id}) do
    where(ReimbursementContract, contractor_legal_entity_id: ^client_id)
  end

  def query(Employee, %{client_type: "MSP", client_id: client_id}) do
    where(Employee, legal_entity_id: ^client_id)
  end

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
      limit = limit + 1

      queryable
      |> filter(filter)
      |> order_by(^order_by)
      |> limit(^limit)
      |> offset(^offset)
    end
  end

  def query(queryable, _), do: queryable

  defp filter(query, [{:merged_from_legal_entity, filter} | tail]) do
    filter(query, [{:merged_from, filter} | tail])
  end

  defp filter(query, filter), do: Search.filter(query, filter)
end
