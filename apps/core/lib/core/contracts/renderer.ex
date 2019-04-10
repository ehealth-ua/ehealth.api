defmodule Core.Contracts.Renderer do
  @moduledoc false

  alias Core.Contracts.{CapitationContract, ReimbursementContract}

  def render_create_request_content(%CapitationContract{} = contract, references) do
    contract
    |> Map.take(~w(
      contract_number
      contractor_base
      contractor_legal_entity_id
      contractor_owner_id
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      id_form
      issue_city
      misc
      nhs_contract_price
      nhs_legal_entity_id
      nhs_payment_method
      nhs_signer_id
      nhs_signer_base
    )a)
    |> Map.merge(%{
      consent_text: references.consent_text,
      contractor_divisions: render_association(:contractor_divisions, references),
      contractor_employee_divisions: render_association(:contractor_employee_divisions, references)
    })
    |> maybe_put_external_contractors(contract)
  end

  def render_create_request_content(%ReimbursementContract{} = contract, associations) do
    contract
    |> Map.take(~w(
      contract_number
      contractor_base
      contractor_legal_entity_id
      contractor_owner_id
      contractor_payment_details
      id_form
      issue_city
      misc
      medical_program_id
      nhs_legal_entity_id
      nhs_payment_method
      nhs_signer_id
      nhs_signer_base
    )a)
    |> Map.merge(%{
      consent_text: associations.consent_text,
      contractor_divisions: render_association(:contractor_divisions, associations)
    })
  end

  def render_association(:contractor_divisions, associations) do
    associations
    |> Map.get(:contract_divisions)
    |> Enum.map(& &1.division_id)
  end

  def render_association(:contractor_employee_divisions, associations) do
    associations
    |> Map.get(:contract_employees)
    |> Enum.map(&render_association(:contractor_employee_division, &1))
  end

  def render_association(:contractor_employee_division, contract_employee) do
    Map.take(contract_employee, ~w(
      division_id
      declaration_limit
      employee_id
      staff_units
    )a)
  end

  def maybe_put_external_contractors(data, %CapitationContract{external_contractor_flag: true} = contract) do
    Map.put(data, :external_contractors, contract.external_contractors)
  end

  def maybe_put_external_contractors(data, _), do: data
end
