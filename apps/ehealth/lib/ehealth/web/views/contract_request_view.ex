defmodule EHealth.Web.ContractRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{contract_requests: contract_requests}) do
    render_many(contract_requests, __MODULE__, "list_contract_request.json")
  end

  def render("list_contract_request.json", %{contract_request: contract_request}) do
    Map.take(contract_request, ~w(
      id
      contractor_legal_entity_id
      contractor_owner_id
      contractor_base
      status
      status_reason
      nhs_signer_id
      nhs_legal_entity_id
      nhs_signer_base
      issue_city
      nhs_contract_price
      contract_number
      contract_id
      start_date
      end_date
    )a)
  end

  def render("show.json", %{contract_request: contract_request, references: references}) do
    data = Map.take(contract_request, ~w(
      id
      co
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      nhs_signer_base
      nhs_contract_price
      nhs_payment_method
      start_date
      end_date
      id_form
      issue_city
      status
      contract_number
      printout_content
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)

    data
    |> Map.put(
      "contractor_legal_entity",
      render_association(:legal_entity, references, contract_request.contractor_legal_entity_id)
    )
    |> Map.put(
      "nhs_legal_entity",
      render_association(:legal_entity, references, contract_request.nhs_legal_entity_id)
    )
    |> Map.put(
      "contractor_owner",
      render_association(:employee, references, contract_request.contractor_owner_id)
    )
    |> Map.put(
      "nhs_signer",
      render_association(:employee, references, contract_request.nhs_signer_id)
    )
    |> Map.put(
      "contractor_employee_divisions",
      render_association(:employee_divisions, references, contract_request.contractor_employee_divisions || [])
    )
  end

  def render("sign_nhs.json", %{contract_request: contract_request}) do
    Map.take(contract_request, ~w(
      id
      contractor_legal_entity_id
      contractor_owner_id
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      contractor_employee_divisions
      nhs_legal_entity_id
      nhs_signer_base
      nhs_contract_price
      nhs_payment_method
      start_date
      end_date
      id_form
      issue_city
      status
      contract_id
      contract_number
      printout_content
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)
  end

  defp render_association(_, _, nil), do: nil

  defp render_association(:legal_entity, references, id) do
    with %{} = legal_entity <-
           references
           |> Map.get(:legal_entity)
           |> Map.get(id) do
      Map.take(legal_entity, ~w(id name edrpou addresses)a)
    end
  end

  defp render_association(:employee, references, id) do
    with %{} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id speciality)a)
      |> Map.put("party", Map.take(employee.party, ~w(id first_name last_name second_name)a))
    end
  end

  defp render_association(:division, references, id) do
    with %{} = division <-
           references
           |> Map.get(:division)
           |> Map.get(id) do
      Map.take(division, ~w(id name addresses phone email working_hours mountain_group phones)a)
    end
  end

  defp render_association(:employee_divisions, references, employee_divisions) do
    Enum.map(employee_divisions, fn employee_division ->
      employee_division
      |> Map.take(~w(staff_units declaration_limit))
      |> Map.put("employee", render_association(:employee, references, Map.get(employee_division, "employee_id")))
      |> Map.put("division", render_association(:division, references, Map.get(employee_division, "division_id")))
    end)
  end
end
