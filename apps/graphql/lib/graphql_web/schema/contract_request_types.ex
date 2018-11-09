defmodule GraphQLWeb.Schema.ContractRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2, load_by_parent: 2, load_by_parent: 3]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ContractRequests.ContractRequest
  alias Core.Contracts.Contract
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias GraphQLWeb.Loaders.{IL, PRM}
  alias GraphQLWeb.Resolvers.ContractRequestResolver

  @status_approved ContractRequest.status(:approved)
  @status_declined ContractRequest.status(:declined)
  @status_in_process ContractRequest.status(:in_process)
  @status_new ContractRequest.status(:new)
  @status_nhs_signed ContractRequest.status(:nhs_signed)
  @status_pending_nhs_sign ContractRequest.status(:pending_nhs_sign)
  @status_signed ContractRequest.status(:signed)
  @status_terminated ContractRequest.status(:terminated)

  @nhs_payment_method_backward ContractRequest.nhs_payment_method(:backward)
  @nhs_payment_method_forward ContractRequest.nhs_payment_method(:forward)

  object :contract_request_queries do
    connection field(:contract_requests, node_type: :contract_request) do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:filter, :contract_request_filter)
      arg(:order_by, :contract_request_order_by, default_value: :inserted_at_desc)

      resolve(&ContractRequestResolver.list_contract_requests/2)
    end

    field :contract_request, :contract_request do
      meta(:scope, ~w(contract_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :contract_request)

      resolve(
        load_by_args(IL, fn _args, %{context: context} ->
          {ContractRequest, Map.take(context, ~w(client_id client_type)a)}
        end)
      )
    end
  end

  input_object :contract_request_filter do
    field(:database_id, :id)
    field(:contractor_legal_entity_edrpou, :string)
    field(:contract_number, :string)
    field(:status, :contract_request_status)
    field(:start_date, :date_interval)
    field(:end_date, :date_interval)
    field(:assignee_id, :id)
    field(:assignee_name, :string)
  end

  enum :contract_request_order_by do
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

  connection node_type: :contract_request do
    field :nodes, list_of(:contract_request) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  object :contract_request_mutations do
    payload field(:update_contract_request) do
      meta(:scope, ~w(contract_request:update))

      middleware(ParseIDs, id: :contract_request, nhs_signer_id: :employee)

      input do
        field(:id, non_null(:id))
        field(:nhs_signer_id, :id)
        field(:nhs_signer_base, :string)
        field(:nhs_contract_price, :float)
        field(:issue_city, :string)
        field(:miscellaneous, :string)
        field(:nhs_payment_method, :nhs_payment_method)
      end

      output do
        field(:contract_request, :contract_request)
      end

      resolve(&ContractRequestResolver.update/2)
    end

    payload field(:approve_contract_request) do
      meta(:scope, ~w(contract_request:update))
      middleware(ParseIDs, id: :contract_request)

      input do
        field(:id, non_null(:id))
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:contract_request, :contract_request)
      end

      resolve(&ContractRequestResolver.approve/2)
    end

    payload field(:decline_contract_request) do
      meta(:scope, ~w(contract_request:update))
      middleware(ParseIDs, id: :contract_request)

      input do
        field(:id, non_null(:id))
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:contract_request, :contract_request)
      end

      resolve(&ContractRequestResolver.decline/2)
    end

    payload field(:assign_contract_request) do
      meta(:scope, ~w(contract_request:update))

      middleware(ParseIDs, id: :contract_request, employee_id: :employee)

      input do
        field(:id, non_null(:id))
        field(:employee_id, non_null(:id))
      end

      output do
        field(:contract_request, :contract_request)
      end

      resolve(&ContractRequestResolver.update_assignee/2)
    end

    payload field(:sign_contract_request) do
      meta(:scope, ~w(contract_request:sign))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      middleware(ParseIDs, id: :contract_request)

      input do
        field(:id, non_null(:id))
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:contract_request, :contract_request)
      end

      resolve(&ContractRequestResolver.sign/2)
    end
  end

  node object(:contract_request) do
    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:parent_contract, :contract, resolve: load_by_parent(PRM, Contract))
    field(:previous_request, :contract_request, resolve: dataloader(IL))
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
    field(:miscellaneous, :string, resolve: fn _, res -> {:ok, res.source.misc} end)

    field(:to_sign_content, :json, resolve: &ContractRequestResolver.get_to_sign_content/3)

    field(
      :attached_documents,
      non_null(list_of(:contract_document)),
      resolve: &ContractRequestResolver.get_attached_documents/3
    )

    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, :naive_datetime)
    field(:updated_at, :naive_datetime)
  end

  enum :contract_request_status do
    value(:approved, as: @status_approved)
    value(:declined, as: @status_declined)
    value(:in_process, as: @status_in_process)
    value(:new, as: @status_new)
    value(:nhs_signed, as: @status_nhs_signed)
    value(:pending_nhs_sign, as: @status_pending_nhs_sign)
    value(:signed, as: @status_signed)
    value(:terminated, as: @status_terminated)
  end

  object :contractor_payment_details do
    field(:bank_name, non_null(:string))
    field(:mfo, non_null(:string), resolve: fn _, res -> Map.fetch(res.source, "MFO") end)
    field(:payer_account, non_null(:string))
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

  enum :nhs_payment_method do
    value(:backward, as: @nhs_payment_method_backward)
    value(:forward, as: @nhs_payment_method_forward)
  end

  object :contract_document do
    field(:type, non_null(:contract_documents_type))
    field(:url, non_null(:string))
  end

  enum :contract_documents_type do
    value(:contract_request_additional_document, as: "CONTRACT_REQUEST_ADDITIONAL_DOCUMENT")
    value(:contract_request_statute, as: "CONTRACT_REQUEST_STATUTE")
    value(:signed_content, as: "SIGNED_CONTENT")
  end
end
