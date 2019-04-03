defmodule GraphQL.Schema.ContractTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias GraphQL.Resolvers.Contract, as: ContractResolver

  @capitation CapitationContract.type()
  @reimbursement ReimbursementContract.type()

  @contract_status_terminated CapitationContract.status(:terminated)
  @contract_status_verified CapitationContract.status(:verified)

  object :contract_mutations do
    payload field(:terminate_contract) do
      meta(:scope, ~w(contract:terminate))
      meta(:client_metadata, ~w(client_id client_type)a)

      input do
        field(:id, non_null(:id))
        field(:reason, :string)
        # Dictionary: CONTRACT_STATUS_REASON
        field(:status_reason, non_null(:string))
      end

      output do
        field(:contract, :contract)
      end

      middleware(ParseIDs, id: [:capitation_contract, :reimbursement_contract])
      resolve(&ContractResolver.terminate/2)
    end

    payload field(:prolongate_contract) do
      meta(:scope, ~w(contract:update))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
        field(:end_date, non_null(:date))
      end

      output do
        field(:contract, :contract)
      end

      middleware(ParseIDs, id: [:capitation_contract, :reimbursement_contract])
      resolve(&ContractResolver.prolongate/2)
    end

    payload field(:suspend_contract) do
      meta(:scope, ~w(contract:update))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
        field(:is_suspended, non_null(:boolean))
        field(:reason, :string)
        # Dictionary: CONTRACT_STATUS_REASON
        field(:status_reason, non_null(:string))
      end

      output do
        field(:contract, :contract)
      end

      middleware(ParseIDs, id: [:capitation_contract, :reimbursement_contract])
      resolve(&ContractResolver.suspend/2)
    end
  end

  interface :contract do
    field(:id, non_null(:id))
    field(:database_id, non_null(:uuid))
    field(:contract_number, :string)
    field(:parent_contract, :contract)
    field(:id_form, non_null(:string))
    field(:status, non_null(:contract_status))
    field(:status_reason, :string)
    field(:reason, :string)
    field(:issue_city, :string)
    field(:printout_content, :string)
    field(:start_date, non_null(:date))
    field(:end_date, non_null(:date))
    field(:is_suspended, non_null(:boolean))
    field(:contractor_legal_entity, non_null(:legal_entity))
    field(:contractor_owner, non_null(:employee))
    field(:contractor_base, non_null(:string))
    field(:contractor_payment_details, non_null(:contractor_payment_details))
    field(:contractor_divisions, :division_connection)
    field(:nhs_signer, :employee)
    field(:nhs_legal_entity, :legal_entity)
    field(:nhs_signer_base, :string)
    # Dictionary: CONTRACT_PAYMENT_METHOD
    field(:nhs_payment_method, :string)
    field(:attached_documents, non_null(list_of(:contract_document)))
    field(:to_create_request_content, non_null(:json))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))

    resolve_type(fn
      %{type: @capitation}, _ -> :capitation_contract
      %{type: @reimbursement}, _ -> :reimbursement_contract
      _, _ -> nil
    end)
  end

  enum :legal_entity_relation do
    value(:merged_from, as: :merged_from)
    value(:merged_to, as: :merged_to)
  end

  enum :contract_status do
    value(:terminated, as: @contract_status_terminated)
    value(:verified, as: @contract_status_verified)
  end
end
