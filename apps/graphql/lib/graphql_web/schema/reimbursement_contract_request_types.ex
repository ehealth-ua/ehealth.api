defmodule GraphQLWeb.Schema.ReimbursementContractRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2, load_by_parent: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts.ReimbursementContract
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.MedicalPrograms.MedicalProgram
  alias GraphQLWeb.Loaders.{IL, PRM}
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.{ContractRequestResolver, ReimbursementContractRequestResolver}

  object :reimbursement_contract_request_queries do
    connection field(:reimbursement_contract_requests, node_type: :reimbursement_contract_request) do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS PHARMACY))

      arg(:filter, :reimbursement_contract_request_filter)
      arg(:order_by, :reimbursement_contract_request_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        contract_number: :equal,
        status: :equal,
        start_date: :in,
        end_date: :in,
        assignee: [
          database_id: :equal,
          employee_type: :in,
          status: :equal,
          is_active: :equal,
          legal_entity: [database_id: :equal, edrpou: :equal, nhs_verified: :equal, nhs_reviewed: :equal]
          # TODO: implement resolver-independent FTS
          # party: [full_name: :full_text_search]
        ],
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

      resolve(&ReimbursementContractRequestResolver.list_contract_requests/2)
    end

    field :reimbursement_contract_request, :reimbursement_contract_request do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS PHARMACY))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :reimbursement_contract_request)

      resolve(
        load_by_args(IL, fn _args, %{context: context} ->
          {ReimbursementContractRequest, Map.take(context, ~w(client_id client_type)a)}
        end)
      )
    end
  end

  input_object :reimbursement_contract_request_filter do
    field(:database_id, :id)
    field(:contract_number, :string)
    field(:status, :contract_request_status)
    field(:start_date, :date_interval)
    field(:end_date, :date_interval)
    field(:assignee, :employee_filter)
    field(:contractor_legal_entity, :legal_entity_filter)
    field(:medical_program, :medical_program_filter)
  end

  enum :reimbursement_contract_request_order_by do
    value(:end_date_asc)
    value(:end_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:medical_program_name_asc)
    value(:medical_program_name_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :reimbursement_contract_request do
    field :nodes, list_of(:reimbursement_contract_request) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:reimbursement_contract_request) do
    interface(:contract_request)

    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:parent_contract, :reimbursement_contract, resolve: load_by_parent(PRM, ReimbursementContract))
    field(:previous_request, :reimbursement_contract_request, resolve: dataloader(IL))
    field(:assignee, :employee, resolve: load_by_parent(PRM, Employee))
    field(:id_form, non_null(:string))
    field(:status, non_null(:contract_request_status))
    field(:status_reason, :string)
    field(:issue_city, :string)
    field(:printout_content, :string, resolve: &ContractRequestResolver.get_printout_content/3)
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:contractor_legal_entity, non_null(:legal_entity), resolve: load_by_parent(PRM, LegalEntity))
    field(:contractor_owner, non_null(:employee), resolve: load_by_parent(PRM, Employee))
    field(:contractor_base, non_null(:string))
    field(:contractor_payment_details, non_null(:contractor_payment_details))
    field(:contractor_divisions, list_of(:division), resolve: load_by_parent(PRM, Division))
    field(:nhs_signer, :employee, resolve: load_by_parent(PRM, Employee))
    field(:nhs_legal_entity, :legal_entity, resolve: load_by_parent(PRM, LegalEntity))
    field(:nhs_signer_base, :string)
    field(:nhs_payment_method, :nhs_payment_method)

    field(:attached_documents, non_null(list_of(:contract_document)),
      resolve: &ContractRequestResolver.get_attached_documents/3
    )

    field(:miscellaneous, :string, resolve: fn _, res -> {:ok, res.source.misc} end)
    field(:to_approve_content, :json)
    field(:to_decline_content, :json)
    field(:to_sign_content, :json)
    field(:medical_program, :medical_program, resolve: load_by_parent(PRM, MedicalProgram))
    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end
end
