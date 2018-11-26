defmodule Core.ContractRequests.ContractRequest do
  @moduledoc false

  @inheritance_column :type

  defmacro __using__(opts) do
    {inheritance_name, opts} = Keyword.pop(opts, :inheritance_name)

    unless inheritance_name do
      raise("Please define inheritance name for ContractRequest")
    end

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Ecto.UUID

      @status_new "NEW"
      @status_in_process "IN_PROCESS"
      @status_declined "DECLINED"
      @status_approved "APPROVED"
      @status_pending_nhs_sign "PENDING_NHS_SIGN"
      @status_nhs_signed "NHS_SIGNED"
      @status_signed "SIGNED"
      @status_terminated "TERMINATED"

      @nhs_payment_method_backward "BACKWARD"
      @nhs_payment_method_forward "FORWARD"

      def status(:new), do: @status_new
      def status(:in_process), do: @status_in_process
      def status(:declined), do: @status_declined
      def status(:approved), do: @status_approved
      def status(:pending_nhs_sign), do: @status_pending_nhs_sign
      def status(:nhs_signed), do: @status_nhs_signed
      def status(:signed), do: @status_signed
      def status(:terminated), do: @status_terminated

      def nhs_payment_method(:backward), do: @nhs_payment_method_backward
      def nhs_payment_method(:forward), do: @nhs_payment_method_forward

      def unquote(@inheritance_column)(), do: unquote(inheritance_name)

      @derive {Jason.Encoder, except: [:__meta__, :previous_request]}
      @primary_key {:id, :binary_id, autogenerate: true}
      schema "contract_requests" do
        field(unquote(@inheritance_column), :string, default: unquote(inheritance_name))
        field(:contractor_legal_entity_id, UUID)
        field(:contractor_owner_id, UUID)
        field(:contractor_base, :string)
        field(:contractor_payment_details, :map)
        field(:contractor_divisions, {:array, UUID})
        field(:start_date, :date)
        field(:end_date, :date)
        field(:nhs_legal_entity_id, UUID)
        field(:nhs_signer_id, UUID)
        field(:nhs_signer_base, :string)
        field(:nhs_signed_date, :date)
        field(:issue_city, :string)
        field(:status, :string)
        field(:status_reason, :string)
        field(:nhs_payment_method, :string)
        field(:contract_number, :string)
        field(:contract_id, UUID)
        field(:parent_contract_id, UUID)
        field(:contractor_signed, :boolean)
        field(:printout_content, :string)
        field(:id_form, :string)
        field(:data, :map)
        field(:misc, :string)
        field(:assignee_id, UUID)
        field(:inserted_by, UUID)
        field(:updated_by, UUID)

        belongs_to(:previous_request, __MODULE__, type: UUID)

        timestamps()

        if fields = unquote(opts)[:fields] do
          for args <- fields do
            case args do
              {field, type, opts} -> field(field, type, opts)
              {field, type} -> field(field, type)
            end
          end
        end

        if belongs_to = unquote(opts)[:belongs_to] do
          for {key, queryable, opts} <- belongs_to do
            belongs_to(key, queryable, opts)
          end
        end

        if has_many = unquote(opts)[:has_many] do
          for {key, queryable, opts} <- has_many do
            has_many(key, queryable, opts)
          end
        end
      end
    end
  end
end
