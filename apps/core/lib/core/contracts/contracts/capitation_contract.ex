defmodule Core.Contracts.CapitationContract do
  @moduledoc false

  import Ecto.Changeset

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts.ContractEmployee

  @inheritance_name CapitationContractRequest.type()

  @fields_required ~w(
    id
    start_date
    end_date
    status
    contractor_legal_entity_id
    contractor_owner_id
    contractor_base
    contractor_payment_details
    contractor_rmsp_amount
    nhs_legal_entity_id
    nhs_signer_id
    nhs_payment_method
    nhs_signer_base
    issue_city
    nhs_contract_price
    contract_number
    contract_request_id
    is_suspended
    is_active
    inserted_by
    updated_by
    id_form
    nhs_signed_date
  )a

  @fields_optional ~w(
    parent_contract_id
    status_reason
    external_contractor_flag
    external_contractors
  )a

  use Core.Contracts.Contract,
    inheritance_name: @inheritance_name,
    fields: [
      {:contractor_rmsp_amount, :integer},
      {:external_contractor_flag, :boolean},
      {:external_contractors, {:array, :map}},
      {:nhs_contract_price, :float}
    ],
    has_many: [
      {:contract_employees, ContractEmployee, foreign_key: :contract_id},
      {:contract_employees_divisions, [through: [:contract_employees, :division]], []}
    ]

  def changeset(%__MODULE__{} = contract, attrs) do
    inserted_by = Map.get(attrs, :inserted_by)
    updated_by = Map.get(attrs, :updated_by)

    attrs =
      case Map.get(attrs, :contractor_employee_divisions) do
        nil ->
          attrs

        contractor_employee_divisions ->
          contractor_employee_divisions =
            Enum.map(
              contractor_employee_divisions,
              &(&1
                |> Map.put("start_date", NaiveDateTime.from_erl!({Date.to_erl(attrs.start_date), {0, 0, 0}}))
                |> Map.put("inserted_by", inserted_by)
                |> Map.put("updated_by", updated_by))
            )

          Map.put(attrs, :contract_employees, contractor_employee_divisions)
      end

    attrs =
      case Map.get(attrs, :contractor_divisions) do
        nil ->
          attrs

        contractor_divisions ->
          contractor_divisions =
            Enum.map(
              contractor_divisions,
              &%{"division_id" => &1, "inserted_by" => inserted_by, "updated_by" => updated_by}
            )

          Map.put(attrs, :contract_divisions, contractor_divisions)
      end

    contract
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> cast_assoc(:contract_employees)
    |> cast_assoc(:contract_divisions)
    |> validate_required(@fields_required)
  end
end
