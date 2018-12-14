defmodule GraphQLWeb.Schema.ReimbursementContractTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2, load_by_parent: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts.ReimbursementContract
  alias GraphQLWeb.Loaders.IL
  alias GraphQLWeb.Loaders.PRM
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.ContractResolver
  alias GraphQLWeb.Resolvers.ReimbursementContractResolver

  object :reimbursement_contract_queries do
    connection field(:reimbursement_contracts, node_type: :reimbursement_contract) do
      meta(:scope, ~w(contract:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS PHARMACY))

      arg(:filter, :reimbursement_contract_filter)
      arg(:order_by, :reimbursement_contract_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        contract_number: :equal,
        status: :equal,
        start_date: :in,
        end_date: :in,
        is_suspended: :equal,
        legal_entity_relation: :equal,
        contractor_legal_entity: [
          database_id: :equal,
          edrpou: :equal,
          nhs_verified: :equal,
          nhs_reviewed: :equal
        ],
        medical_program: [
          database_id: :equal,
          name: :like,
          is_active: :equal
        ]
      )

      resolve(&ReimbursementContractResolver.list_contracts/2)
    end

    field :reimbursement_contract, :reimbursement_contract do
      meta(:scope, ~w(contract:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS PHARMACY))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :reimbursement_contract)

      resolve(
        load_by_args(PRM, fn _args, %{context: context} ->
          {ReimbursementContract, Map.take(context, ~w(client_id client_type)a)}
        end)
      )
    end
  end

  input_object :reimbursement_contract_filter do
    field(:database_id, :id)
    field(:contractor_legal_entity, :legal_entity_filter)
    field(:contract_number, :string)
    field(:medical_program, :medical_program_filter)
    field(:status, :contract_status)
    field(:start_date, :date_interval)
    field(:end_date, :date_interval)
    field(:legal_entity_relation, :legal_entity_relation)
    field(:is_suspended, :boolean)
  end

  enum :reimbursement_contract_order_by do
    value(:contractor_legal_entity_edrpou_asc)
    value(:contractor_legal_entity_edrpou_desc)
    value(:end_date_asc)
    value(:end_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:is_suspended_asc)
    value(:is_suspended_desc)
    value(:medical_program_name_asc)
    value(:medical_program_name_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :reimbursement_contract do
    field :nodes, list_of(:reimbursement_contract) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:reimbursement_contract) do
    interface(:contract)

    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:parent_contract_id, :id)
    field(:parent_contract, :contract, resolve: dataloader(PRM))
    field(:contract_request_id, non_null(:id))

    field(:contract_request, non_null(:reimbursement_contract_request),
      resolve: load_by_parent(IL, ReimbursementContractRequest)
    )

    field(:id_form, non_null(:string))
    field(:status, non_null(:contract_status))
    field(:status_reason, :string)
    field(:issue_city, :string)
    field(:printout_content, :string, resolve: &ContractResolver.get_printout_content/3)
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:is_suspended, non_null(:boolean))
    field(:contractor_legal_entity, non_null(:legal_entity), resolve: dataloader(PRM))
    field(:contractor_owner, non_null(:employee), resolve: dataloader(PRM))
    field(:contractor_base, non_null(:string))
    field(:contractor_payment_details, non_null(:contractor_payment_details))

    connection field(:contractor_divisions, node_type: :division) do
      arg(:filter, :division_filter)
      arg(:order_by, :division_order_by, default_value: :inserted_at_asc)

      # TODO: Replace it with `GraphQLWeb.Middleware.Filtering`
      middleware(GraphQLWeb.Middleware.FilterArgument)
      resolve(&ReimbursementContractResolver.load_contract_divisions/3)
    end

    field(:nhs_signer, :employee, resolve: dataloader(PRM))
    field(:nhs_legal_entity, :legal_entity, resolve: dataloader(PRM))
    field(:nhs_signer_base, :string)
    field(:nhs_payment_method, :nhs_payment_method)

    field(:attached_documents, non_null(list_of(:contract_document)),
      resolve: &ReimbursementContractResolver.get_attached_documents/3
    )

    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
    field(:medical_program, :medical_program, resolve: dataloader(PRM))
  end
end
