defmodule Core.Contracts.Renderer do
  @moduledoc false

  alias Core.Contracts.{CapitationContract, ReimbursementContract}

  def render_create_request_content(%CapitationContract{} = contract, references) do
    data = Map.take(contract, ~w(
      contract_number
      contractor_base
      contractor_legal_entity_id
      contractor_owner_id
      contractor_payment_details
      contractor_rmsp_amount
      end_date
      external_contractor_flag
      external_contractors
      id_form
      issue_city
      misc
      nhs_contract_price
      nhs_legal_entity_id
      nhs_payment_method
      nhs_signer_id
      nhs_signer_base
      start_date
    )a)

    Map.merge(data, %{
      contractor_divisions: render_association(:contractor_divisions, references),
      contractor_employee_divisions: render_association(:contractor_employee_divisions, references)
    })
  end

  def render_create_request_content(%ReimbursementContract{} = contract, references) do
    data = Map.take(contract, ~w(
      contract_number
      contractor_base
      contractor_legal_entity_id
      contractor_owner_id
      contractor_payment_details
      end_date
      id_form
      issue_city
      misc
      medical_program_id
      nhs_legal_entity_id
      nhs_payment_method
      nhs_signer_id
      nhs_signer_base
      start_date
    )a)

    Map.merge(data, %{
      contractor_divisions: render_association(:contractor_divisions, references)
    })
  end

  def render_association(:contractor_divisions, references) do
    references
    |> Map.get(:contract_divisions)
    |> Enum.map(& &1.division_id)
  end

  def render_association(:contractor_employee_divisions, references) do
    references
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
end
