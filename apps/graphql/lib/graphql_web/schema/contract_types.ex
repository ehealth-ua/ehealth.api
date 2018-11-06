defmodule GraphQLWeb.Schema.ContractTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_parent: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Contracts.Contract
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias GraphQLWeb.Loaders.PRM
  alias GraphQLWeb.Resolvers.ContractResolver

  @contract_status_terminated Contract.status(:terminated)
  @contract_status_verified Contract.status(:verified)

  object :contract_queries do
    connection field(:contracts, node_type: :contract) do
      meta(:scope, ~w(contract:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:filter, :contract_filter)
      arg(:order_by, :contract_order_by, default_value: :inserted_at_desc)

      resolve(&ContractResolver.list_contracts/2)
    end

    #    field :contract, :contract do
    #      meta(:scope, ~w(contract:read))
    #      meta(:client_metadata, ~w(client_id client_type)a)
    #      meta(:allowed_clients, ~w(NHS MSP))
    #
    #      arg(:id, non_null(:id))
    #
    #      middleware(ParseIDs, id: :contract)
    #
    #      resolve(
    #        load_by_args(IL, fn _args, %{context: context} ->
    #          {Contract, Map.take(context, ~w(client_id client_type)a)}
    #        end)
    #      )
    #    end
  end

  input_object :contract_filter do
    field(:contractor_legal_entity_edrpou, :string)
    field(:contract_number, :string)
    field(:status, :contract_status)
    field(:start_date, :date_interval)
    field(:end_date, :date_interval)
    field(:legal_entity_relation, :legal_entity_relation)
    field(:is_suspended, :string)
  end

  enum :contract_order_by do
    value(:edrpou_asc)
    value(:edrpou_desc)
    value(:end_date_asc)
    value(:end_date_desc)
    value(:status_asc)
    value(:status_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  connection node_type: :contract do
    field :nodes, list_of(:contract) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  object :contract_mutations do
    payload field(:terminate_contract) do
      meta(:scope, ~w(contract:terminate))
      meta(:client_metadata, ~w(client_id client_type)a)

      input do
        field(:id, non_null(:id))
        field(:status_reason, :string)
      end

      output do
        field(:contract, :contract)
      end

      middleware(ParseIDs, id: :contract)
      resolve(&ContractResolver.terminate/2)
    end
  end

  node object(:contract) do
    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:parent_contract_id, :id)
    field(:contract_request_id, non_null(:id))
    field(:id_form, non_null(:string))
    field(:status, non_null(:contract_status))
    field(:status_reason, :string)
    field(:issue_city, :string)
    field(:printout_content, :string)
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:is_suspended, :boolean)
    field(:contractor_legal_entity, non_null(:legal_entity), resolve: load_by_parent(PRM, LegalEntity))
    field(:contractor_owner, non_null(:employee), resolve: load_by_parent(PRM, Employee))
    field(:contractor_base, non_null(:string))
    field(:contractor_payment_details, non_null(:contractor_payment_details))
    field(:contractor_rmsp_amount, non_null(:integer))
    field(:contractor_divisions, list_of(:division), resolve: load_by_parent(PRM, Division))
    field(:contractor_employee_divisions, list_of(:contractor_employee_division))
    field(:external_contractor_flag, non_null(:boolean))
    field(:external_contractors, list_of(:external_contractor))
    field(:nhs_signer, :employee, resolve: load_by_parent(PRM, Employee))
    field(:nhs_legal_entity, :legal_entity, resolve: load_by_parent(PRM, LegalEntity))
    field(:nhs_signer_base, :string)
    field(:nhs_contract_price, :float)
    field(:nhs_payment_method, :nhs_payment_method)
    field(:attached_documents, list_of(:contract_document))
  end

  enum :contract_status do
    value(:terminated, as: @contract_status_terminated)
    value(:verified, as: @contract_status_verified)
  end

  enum :legal_entity_relation do
    value(:merged_from, as: :merged_from)
    value(:merged_to, as: :merged_to)
  end
end
