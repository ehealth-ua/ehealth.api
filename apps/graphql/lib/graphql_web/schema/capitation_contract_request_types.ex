defmodule GraphQLWeb.Schema.CapitationContractRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2, load_by_parent: 2, load_by_parent: 3]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts.CapitationContract
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias GraphQLWeb.Loaders.{IL, PRM}
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.{CapitationContractRequestResolver, ContractRequestResolver}

  object :capitation_contract_request_queries do
    connection field(:capitation_contract_requests, node_type: :capitation_contract_request) do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:filter, :capitation_contract_request_filter)
      arg(:order_by, :capitation_contract_request_order_by, default_value: :inserted_at_desc)

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
        ]
      )

      resolve(&CapitationContractRequestResolver.list_contract_requests/2)
    end

    field :capitation_contract_request, :capitation_contract_request do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :capitation_contract_request)

      resolve(
        load_by_args(IL, fn _args, %{context: context} ->
          {CapitationContractRequest, Map.take(context, ~w(client_id client_type)a)}
        end)
      )
    end
  end

  input_object :capitation_contract_request_filter do
    field(:database_id, :id)
    field(:contract_number, :string)
    field(:status, :contract_request_status)
    field(:start_date, :date_interval)
    field(:end_date, :date_interval)
    field(:assignee, :employee_filter)
    field(:contractor_legal_entity, :legal_entity_filter)
  end

  enum :capitation_contract_request_order_by do
    value(:end_date_asc)
    value(:end_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:start_date_asc)
    value(:start_date_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :capitation_contract_request do
    field :nodes, list_of(:capitation_contract_request) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:capitation_contract_request) do
    interface(:contract_request)

    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:parent_contract, :capitation_contract, resolve: load_by_parent(PRM, CapitationContract))
    field(:previous_request, :capitation_contract_request, resolve: dataloader(IL))
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

    field(
      :attached_documents,
      non_null(list_of(:contract_document)),
      resolve: &ContractRequestResolver.get_attached_documents/3
    )

    field(:miscellaneous, :string, resolve: fn _, res -> {:ok, res.source.misc} end)
    field(:to_approve_content, :json, resolve: &ContractRequestResolver.get_to_approve_content/3)
    field(:to_decline_content, :json, resolve: &ContractRequestResolver.get_to_decline_content/3)
    field(:to_sign_content, :json, resolve: &ContractRequestResolver.get_to_sign_content/3)
    field(:contractor_rmsp_amount, non_null(:integer))
    field(:contractor_employee_divisions, list_of(:contractor_employee_division))
    field(:external_contractor_flag, non_null(:boolean))
    field(:external_contractors, list_of(:external_contractor))
    field(:nhs_contract_price, :float)
    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  object :contractor_employee_division do
    field(:staff_units, non_null(:float))
    field(:declaration_limit, non_null(:integer))
    field(:employee, non_null(:employee), resolve: load_by_parent(PRM, Employee, key: "employee_id"))
    field(:division, non_null(:division), resolve: load_by_parent(PRM, Division, key: "division_id"))
  end

  object :external_contractor do
    field(:legal_entity, non_null(:legal_entity), resolve: load_by_parent(PRM, LegalEntity, key: "legal_entity_id"))

    field(:contract, non_null(:external_contractor_contract))
    field(:divisions, non_null(list_of(:external_contractor_divsion)))
  end

  object :external_contractor_contract do
    field(:number, non_null(:string))
    # TODO: this field should be serialized into :date scalar type
    field(:issued_at, non_null(:string))
    # TODO: this field should be serialized into :date scalar type
    field(:expires_at, non_null(:string))
  end

  object :external_contractor_divsion do
    field(:medical_service, non_null(:string))
    field(:division, non_null(:division), resolve: load_by_parent(PRM, Division, key: "id"))
  end
end
