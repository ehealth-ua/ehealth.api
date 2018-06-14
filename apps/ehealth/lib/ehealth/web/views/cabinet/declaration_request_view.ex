defmodule EHealth.Web.Cabinet.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{declaration_requests: declaration_requests}) do
    render_many(declaration_requests, __MODULE__, "declaration_request_short.json")
  end

  def render("declaration_request_short.json", %{declaration_request: %{data: data} = declaration_request}) do
    declaration_request
    |> Map.take(~w(
      id
      declaration_number
      status
    )a)
    |> Map.put(:start_date, Map.get(data, "start_date"))
    |> Map.put(:person, render_association(:person, :list, Map.get(data, "person", %{})))
    |> Map.put(:employee, render_association(:employee, :list, Map.get(data, "employee", %{})))
    |> Map.put(:legal_entity, render_association(:legal_entity, :list, Map.get(data, "legal_entity", %{})))
    |> Map.put(:division, render_association(:division, :list, Map.get(data, "division", %{})))
  end

  def render("declaration_request.json", %{declaration_request: %{data: data} = declaration_request} = assigns) do
    response =
      declaration_request
      |> Map.take(~w(
        id
        declaration_number
        declaration_id
        status
        channel
        inserted_at
        updated_at
      )a)
      |> Map.put(:content, declaration_request.printout_content)
      |> Map.put(:start_date, Map.get(data, "start_date"))
      |> Map.put(:start_date, Map.get(data, "end_date"))
      |> Map.put(:scope, Map.get(data, "scope"))
      |> Map.put(:person_id, get_in(data, ["person", "id"]))
      |> Map.put(:person, render_association(:person, :details, Map.get(data, "person", %{})))
      |> Map.put(:employee, render_association(:employee, :details, Map.get(data, "employee", %{})))
      |> Map.put(:legal_entity, render_association(:legal_entity, :details, Map.get(data, "legal_entity", %{})))
      |> Map.put(:division, render_association(:division, :details, Map.get(data, "division", %{})))

    if Map.get(assigns, :hash) do
      Map.put(response, "seed", assigns.hash)
    else
      response
    end
  end

  defp render_association(_, _, nil), do: nil

  defp render_association(:person, :list, data) do
    Map.take(data, ~w(id first_name last_name second_name))
  end

  defp render_association(:person, :details, data) do
    Map.take(data, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      gender
      tax_id
      phones
      birth_settlement
      birth_country
      documents
      emergency_contact
      confidant_person
    ))
  end

  defp render_association(:employee, :list, data) do
    data
    |> Map.take(~w(id position))
    |> Map.put(:party, render_association(:person, :list, Map.get(data, "party")))
  end

  defp render_association(:employee, :details, data) do
    data
    |> Map.take(~w(
      id
      position
      employee_type
      status
      start_date
      end_date
      division_id
      legal_entity_id
      doctor
    ))
    |> Map.put(:party, render_association(:person, :list, Map.get(data, "party")))
  end

  defp render_association(:legal_entity, :list, data) do
    Map.take(data, ~w(id name short_name legal_form edrpou))
  end

  defp render_association(:legal_entity, :details, data) do
    Map.take(data, ~w(
      id
      name
      short_name
      legal_form
      edrpou
      public_name
      status
      email
      phones
      addresses
    ))
  end

  defp render_association(:division, :list, data) do
    Map.take(data, ~w(id name type status))
  end

  defp render_association(:division, :details, data) do
    Map.take(data, ~w(
      id
      name
      addresses
      phones
      email
    ))
  end
end
