defmodule Core.Contracts.Contract do
  @moduledoc false

  @inheritance_column :type

  defmacro __using__(opts) do
    {inheritance_name, opts} = Keyword.pop(opts, :inheritance_name)

    unless inheritance_name do
      raise("Please define inheritance name for Contract")
    end

    quote do
      use Ecto.Schema

      alias Core.Contracts.ContractDivision
      alias Core.Employees.Employee
      alias Core.LegalEntities.LegalEntity
      alias Core.LegalEntities.RelatedLegalEntity
      alias Ecto.UUID

      @status_verified "VERIFIED"
      @status_terminated "TERMINATED"

      def status(:verified), do: @status_verified
      def status(:terminated), do: @status_terminated

      def unquote(@inheritance_column)(), do: unquote(inheritance_name)

      @primary_key {:id, UUID, autogenerate: false}
      schema "contracts" do
        field(unquote(@inheritance_column), :string, default: unquote(inheritance_name))
        field(:start_date, :date)
        field(:end_date, :date)
        field(:status, :string)
        field(:status_reason, :string)
        field(:reason, :string)
        field(:contractor_base, :string)
        field(:contractor_payment_details, :map)
        field(:nhs_payment_method, :string)
        field(:nhs_signer_base, :string)
        field(:issue_city, :string)
        field(:contract_number, :string)
        field(:contract_request_id, UUID)
        field(:is_active, :boolean)
        field(:is_suspended, :boolean)
        field(:inserted_by, UUID)
        field(:updated_by, UUID)
        field(:id_form, :string)
        field(:nhs_signed_date, :date)

        belongs_to(:contractor_legal_entity, LegalEntity, type: UUID)
        belongs_to(:contractor_owner, Employee, type: UUID)
        belongs_to(:nhs_legal_entity, LegalEntity, type: UUID)
        belongs_to(:nhs_signer, Employee, type: UUID)
        belongs_to(:parent_contract, __MODULE__, type: UUID)

        has_many(:contract_divisions, ContractDivision, foreign_key: :contract_id)
        has_many(:divisions, through: [:contract_divisions, :division])

        has_one(:merged_from, RelatedLegalEntity, foreign_key: :merged_from_id, references: :contractor_legal_entity_id)
        has_many(:merged_to, RelatedLegalEntity, foreign_key: :merged_to_id, references: :contractor_legal_entity_id)

        timestamps(type: :utc_datetime_usec)

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
