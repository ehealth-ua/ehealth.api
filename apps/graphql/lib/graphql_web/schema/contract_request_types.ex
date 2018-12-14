defmodule GraphQLWeb.Schema.ContractRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias GraphQLWeb.Resolvers.ContractRequestResolver

  @capitation_type CapitationContractRequest.type()
  @reimbursement_type ReimbursementContractRequest.type()

  @status_approved CapitationContractRequest.status(:approved)
  @status_declined CapitationContractRequest.status(:declined)
  @status_in_process CapitationContractRequest.status(:in_process)
  @status_new CapitationContractRequest.status(:new)
  @status_nhs_signed CapitationContractRequest.status(:nhs_signed)
  @status_pending_nhs_sign CapitationContractRequest.status(:pending_nhs_sign)
  @status_signed CapitationContractRequest.status(:signed)
  @status_terminated CapitationContractRequest.status(:terminated)

  @nhs_payment_method_backward CapitationContractRequest.nhs_payment_method(:backward)
  @nhs_payment_method_forward CapitationContractRequest.nhs_payment_method(:forward)

  object :contract_request_mutations do
    payload field(:update_contract_request) do
      meta(:scope, ~w(contract_request:update))

      middleware(ParseIDs,
        id: ~w(capitation_contract_request reimbursement_contract_request)a,
        nhs_signer_id: :employee
      )

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
      middleware(ParseIDs, id: [:capitation_contract_request, :reimbursement_contract_request])

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
      middleware(ParseIDs, id: [:capitation_contract_request, :reimbursement_contract_request])

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

      middleware(ParseIDs, id: [:capitation_contract_request, :reimbursement_contract_request], employee_id: :employee)

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

      middleware(ParseIDs, id: [:capitation_contract_request, :reimbursement_contract_request])

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

  interface :contract_request do
    field(:id, non_null(:id))
    field(:database_id, non_null(:id))
    field(:contract_number, :string)
    field(:assignee, :employee)
    field(:id_form, non_null(:string))
    field(:status, non_null(:contract_request_status))
    field(:status_reason, :string)
    field(:issue_city, :string)
    field(:printout_content, :string)
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:contractor_legal_entity, non_null(:legal_entity))
    field(:contractor_owner, non_null(:employee))
    field(:contractor_base, non_null(:string))
    field(:contractor_payment_details, non_null(:contractor_payment_details))
    field(:contractor_divisions, list_of(:division))
    field(:nhs_signer, :employee)
    field(:nhs_legal_entity, :legal_entity)
    field(:nhs_signer_base, :string)
    field(:nhs_payment_method, :nhs_payment_method)
    field(:attached_documents, non_null(list_of(:contract_document)))
    field(:miscellaneous, :string)
    field(:to_approve_content, :json)
    field(:to_decline_content, :json)
    field(:to_sign_content, :json)
    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))

    resolve_type(fn
      %{type: @capitation_type}, _ -> :capitation_contract_request
      %{type: @reimbursement_type}, _ -> :reimbursement_contract_request
      _, _ -> nil
    end)
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
