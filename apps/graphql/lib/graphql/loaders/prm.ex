defmodule GraphQL.Loaders.PRM do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2, limit: 2, offset: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees.Employee
  alias Core.Medications.{INNMDosage, Medication}

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def data, do: Dataloader.Ecto.new(@read_prm_repo, query: &query/2)

  def query(CapitationContract, %{client_type: "MSP", client_id: client_id}) do
    where(CapitationContract, contractor_legal_entity_id: ^client_id)
  end

  def query(ReimbursementContract, %{client_type: "PHARMACY", client_id: client_id}) do
    where(ReimbursementContract, contractor_legal_entity_id: ^client_id)
  end

  def query(Employee, %{client_type: "MSP", client_id: client_id}) do
    where(Employee, legal_entity_id: ^client_id)
  end

  def query(INNMDosage, _args), do: where(INNMDosage, type: ^INNMDosage.type())
  def query(Medication, _args), do: where(Medication, type: ^Medication.type())

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
end
