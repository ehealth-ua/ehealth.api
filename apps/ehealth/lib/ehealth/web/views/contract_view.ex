defmodule EHealth.Web.ContractView do
  @moduledoc false

  use EHealth.Web, :view

  alias Core.ContractRequests.Renderer
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias EHealth.Web.DivisionView

  @capitation CapitationContract.type()
  @reimbursement ReimbursementContract.type()

  def render("index.json", %{contracts: contracts, references: references}) do
    render_many(contracts, __MODULE__, "contract.json", references: references)
  end

  def render("contract.json", %{contract: %{type: @capitation} = contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      type
      start_date
      end_date
      status
      contractor_base
      contractor_legal_entity_id
      nhs_legal_entity_id
      nhs_signer_id
      nhs_signer_base
      issue_city
      contract_number
      is_suspended
      contract_request_id
      parent_contract_id
      id_form
      nhs_signed_date
      external_contractor_flag
      nhs_contract_price
    )a)
    |> Map.merge(%{
      contractor_owner: Renderer.render_association(:employee, references, contract.contractor_owner_id),
      contract_divisions: Enum.map(contract.contract_divisions, &render_association(:contract_division, &1))
    })
  end

  def render("contract.json", %{contract: %{type: @reimbursement} = contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      type
      start_date
      end_date
      status
      contractor_base
      contractor_legal_entity_id
      nhs_legal_entity_id
      nhs_signer_id
      nhs_signer_base
      issue_city
      contract_number
      is_suspended
      contract_request_id
      parent_contract_id
      id_form
      nhs_signed_date
      medical_program_id
    )a)
    |> Map.merge(%{
      contractor_owner: Renderer.render_association(:employee, references, contract.contractor_owner_id),
      contract_divisions: Enum.map(contract.contract_divisions, &render_association(:contract_division, &1))
    })
  end

  def render("show.json", %{contract: %{type: @capitation} = contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      type
      start_date
      end_date
      status
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      nhs_payment_method
      nhs_signer_base
      issue_city
      nhs_contract_price
      contract_number
      is_suspended
      contract_request_id
      parent_contract_id
      id_form
      nhs_signed_date
    )a)
    |> render_associations(contract, references)
  end

  def render("show.json", %{contract: %{type: @reimbursement} = contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      type
      start_date
      end_date
      status
      contractor_base
      contractor_payment_details
      nhs_payment_method
      nhs_signer_base
      issue_city
      contract_number
      is_suspended
      contract_request_id
      parent_contract_id
      id_form
      nhs_signed_date
      medical_program_id
    )a)
    |> render_associations(contract, references)
  end

  def render("terminate.json", %{contract: contract, references: references}) do
    contract
    |> Map.take(~w(
      id
      start_date
      end_date
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      nhs_signer_base
      nhs_contract_price
      nhs_payment_method
      status
      status_reason
      issue_city
      contract_number
      contract_request_id
      is_suspended
      updated_by
      updated_at
      )a)
    |> render_associations(contract, references)
  end

  def render("printout_content.json", %{contract: contract, printout_content: printout_content}) do
    %{id: contract.id, printout_content: printout_content}
  end

  def render("show_employees.json", %{contract_employees: contract_employees, references: references}) do
    render_many(
      contract_employees,
      __MODULE__,
      "contract_employee.json",
      references: references,
      as: :contract_employee
    )
  end

  def render("contract_employee.json", %{contract_employee: contract_employee, references: references}) do
    contract_employee
    |> Map.take(~w(
      contract_id
      division_id
      staff_units
      declaration_limit
    )a)
    |> Map.merge(%{
      start_date: convert_naive_datetime_to_date(contract_employee.start_date),
      end_date: convert_naive_datetime_to_date(contract_employee.end_date),
      employee: render_association(:employee, references, contract_employee.employee_id)
    })
  end

  defp convert_naive_datetime_to_date(%NaiveDateTime{} = value), do: NaiveDateTime.to_date(value)
  defp convert_naive_datetime_to_date(value), do: value

  def render_association(:contract_division, contract_division) do
    Map.take(contract_division, ~w(id name)a)
  end

  def render_association(:employee_divisions, references, employee_divisions) do
    Enum.map(employee_divisions, fn employee_division ->
      employee_division
      |> Map.take(~w(division_id staff_units declaration_limit)a)
      |> Map.put("employee", Renderer.render_association(:employee_division, references, employee_division.employee_id))
    end)
  end

  def render_association(:contractor_divisions, references, contractor_divisions) do
    Enum.map(contractor_divisions, &render_association(:division, references, &1))
  end

  def render_association(:division, references, contract_division) do
    with %{} = division <- references |> Map.get(:division) |> Map.get(contract_division.division_id) do
      division
      |> Map.take(~w(id name phone email working_hours mountain_group phones)a)
      |> Map.put(:addresses, render_many(division.addresses, DivisionView, "division_addresses.json", as: :address))
    end
  end

  def render_association(:employee, references, id) do
    with %{} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id speciality)a)
      |> Map.put(:party, Map.take(employee.party, ~w(first_name last_name second_name)a))
    end
  end

  def render_associations(data, %{type: @capitation} = contract, references) do
    Map.merge(data, %{
      nhs_signer: Renderer.render_association(:employee, references, contract.nhs_signer_id),
      nhs_legal_entity: Renderer.render_association(:legal_entity, references, contract.nhs_legal_entity_id),
      contractor_owner: Renderer.render_association(:employee, references, contract.contractor_owner_id),
      contractor_legal_entity:
        Renderer.render_association(:legal_entity, references, contract.contractor_legal_entity_id),
      external_contractors:
        Renderer.render_association(:external_contractors, references, contract.external_contractors || []),
      contractor_divisions: render_association(:contractor_divisions, references, contract.contract_divisions || []),
      contractor_employee_divisions:
        render_association(:employee_divisions, references, contract.contract_employees || [])
    })
  end

  def render_associations(data, %{type: @reimbursement} = contract, references) do
    Map.merge(data, %{
      nhs_signer: Renderer.render_association(:employee, references, contract.nhs_signer_id),
      nhs_legal_entity: Renderer.render_association(:legal_entity, references, contract.nhs_legal_entity_id),
      contractor_owner: Renderer.render_association(:employee, references, contract.contractor_owner_id),
      contractor_legal_entity:
        Renderer.render_association(:legal_entity, references, contract.contractor_legal_entity_id),
      contractor_divisions: render_association(:contractor_divisions, references, contract.contract_divisions || [])
    })
  end
end
