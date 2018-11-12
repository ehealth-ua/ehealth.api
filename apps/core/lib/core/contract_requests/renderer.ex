defmodule Core.ContractRequests.Renderer do
  @moduledoc """
  Contract Request should know how to render itself,
  because it's important for Digital Signature validation
  and validation can be used in different applications
  """

  alias Core.ContractRequests.ContractRequest

  def render(%ContractRequest{} = contract_request, references) do
    data = Map.take(contract_request, ~w(
      id
      contractor_base
      contractor_payment_details
      contractor_rmsp_amount
      external_contractor_flag
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
      parent_contract_id
      status_reason
      previous_request_id
      assignee_id
    )a)

    %{
      nhs_signer_id: nhs_signer_id,
      nhs_legal_entity_id: nhs_legal_entity_id,
      contractor_legal_entity_id: contractor_legal_entity_id,
      contractor_owner_id: contractor_owner_id,
      contractor_employee_divisions: contractor_employee_divisions,
      contractor_divisions: contractor_divisions,
      external_contractors: external_contractors
    } = contract_request

    Map.merge(data, %{
      contractor_legal_entity: render_association(:legal_entity, references, contractor_legal_entity_id),
      nhs_legal_entity: render_association(:legal_entity, references, nhs_legal_entity_id),
      contractor_owner: render_association(:employee, references, contractor_owner_id),
      nhs_signer: render_association(:employee, references, nhs_signer_id),
      contractor_divisions: render_association(:contractor_divisions, references, contractor_divisions || []),
      external_contractors: render_association(:external_contractors, references, external_contractors || []),
      contractor_employee_divisions:
        render_association(:employee_divisions, references, contractor_employee_divisions || [])
    })
  end

  def render_review_content(%ContractRequest{} = contract_request, associations) do
    {legal_entity, review_fields} = Map.pop(associations, :contractor_legal_entity)
    contractor_legal_entity = Map.take(legal_entity, ~w(id edrpou name)a)

    contract_request
    |> Map.take(~w(id)a)
    |> Map.merge(review_fields)
    |> Map.put(:contractor_legal_entity, contractor_legal_entity)
  end

  def render_association(_, _, nil), do: nil

  def render_association(:legal_entity, references, id) do
    with %{} = legal_entity <-
           references
           |> Map.get(:legal_entity)
           |> Map.get(id) do
      Map.take(legal_entity, ~w(id name edrpou addresses)a)
    end
  end

  def render_association(:employee_division, references, id) do
    with %{} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id speciality)a)
      |> Map.put("party", Map.take(employee.party, ~w(first_name last_name second_name)a))
    end
  end

  def render_association(:employee, references, id) do
    with %{} = employee <-
           references
           |> Map.get(:employee)
           |> Map.get(id) do
      employee
      |> Map.take(~w(id)a)
      |> Map.put("party", Map.take(employee.party, ~w(first_name last_name second_name)a))
    end
  end

  def render_association(:division, references, id) do
    address_fields = ~w(
      apartment
      area
      building
      country
      region
      settlement
      settlement_id
      settlement_type
      street
      street_type
      type
      zip
    )a

    with %{} = division <- references |> Map.get(:division) |> Map.get(id) do
      addresses = Enum.map(division.addresses, &Map.take(&1, address_fields))

      division
      |> Map.take(~w(id name phone email working_hours mountain_group phones)a)
      |> Map.put(:addresses, addresses)
    end
  end

  def render_association(:employee_divisions, references, employee_divisions) do
    Enum.map(employee_divisions, fn employee_division ->
      employee_division
      |> Map.take(~w(division_id staff_units declaration_limit))
      |> Map.put(
        "employee",
        render_association(:employee_division, references, Map.get(employee_division, "employee_id"))
      )
    end)
  end

  def render_association(:external_contractor, references, external_contractor) do
    legal_entity =
      references
      |> Map.get(:legal_entity)
      |> Map.get(external_contractor["legal_entity_id"]) || %{}

    divisions = external_contractor["divisions"] || []

    divisions =
      Enum.map(divisions, fn %{"id" => id, "medical_service" => medical_service} ->
        division =
          references
          |> Map.get(:division)
          |> Map.get(id) || %{}

        %{"id" => id, "name" => division.name, "medical_service" => medical_service}
      end)

    external_contractor
    |> Map.take(~w(contract))
    |> Map.put("legal_entity", Map.take(legal_entity, ~w(id name)a))
    |> Map.put("divisions", divisions)
  end

  def render_association(:contractor_divisions, references, contractor_divisions) do
    Enum.map(contractor_divisions, &render_association(:division, references, &1))
  end

  def render_association(:external_contractors, references, external_contractors) do
    Enum.map(external_contractors, &render_association(:external_contractor, references, &1))
  end
end
