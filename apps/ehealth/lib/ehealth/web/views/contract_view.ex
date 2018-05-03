defmodule EHealth.Web.ContractView do
  @moduledoc false

  use EHealth.Web, :view

  def render("show.json", %{contract: contract, references: references}) do
    contract_request = get_in(references, [:contract_request, contract["contract_request_id"]])

    contract
    |> Map.take(~w(
      id
      start_date
      end_date
      status
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
      external_contractors
      nhs_payment_method
      nhs_signer_base
      nhs_payment_details
      issue_city
      price
      contract_number
      is_suspended
      contract_request_id
      nhs_contract_price
    ))
    |> Map.merge(Map.take(contract_request, ~w(contractor_employee_divisions nhs_contract_price)a))
    |> Map.put(
      "contractor_legal_entity",
      render_association(:legal_entity, references, contract["contractor_legal_entity_id"])
    )
    |> Map.put("nhs_legal_entity", render_association(:legal_entity, references, contract["nhs_legal_entity_id"]))
    |> Map.put("contractor_owner", render_association(:employee_short, references, contract["contractor_owner_id"]))
    |> Map.put("nhs_signer", render_association(:employee_short, references, contract["nhs_signer_id"]))
    |> Map.put(
      "contractor_employee_divisions",
      render_association(:employee_divisions, references, contract_request.contractor_employee_divisions || [])
    )
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

  defp render_association(:employee_short, references, id) do
    with %{party: party} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id)a)
      |> Map.merge(Map.take(party, ~w(first_name last_name second_name)a))
    end
  end

  defp render_association(:employee_divisions, references, employee_divisions) do
    Enum.map(employee_divisions, fn employee_division ->
      employee_division
      |> Map.take(~w(staff_units declaration_limit))
      |> Map.put("employee", render_association(:employee, references, employee_division["employee_id"]))
      |> Map.put("division", render_association(:division, references, employee_division["division_id"]))
    end)
  end

  defp render_association(:employee, references, id) do
    with %{party: party} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id)a)
      |> Map.merge(Map.take(party, ~w(first_name last_name second_name specialities)a))
    end
  end

  defp render_association(:division, references, id) do
    with %{} = division <-
           references
           |> Map.get(:division)
           |> Map.get(id) do
      Map.take(division, ~w(id name addresses phones email working_hours mountain_group)a)
    end
  end
end
