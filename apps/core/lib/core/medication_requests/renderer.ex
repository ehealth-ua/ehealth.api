defmodule Core.MedicationRequests.Renderer do
  @moduledoc false

  alias Core.Divisions.Division
  alias Core.Divisions.Renderer, as: DivisionsRenderer
  alias Core.Employees.Employee
  alias Core.LegalEntities.Renderer, as: LegalEntitiesRenderer
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Persons.Renderer, as: PersonsRenderer

  def render("show.json", medication_request) do
    legal_entity = medication_request["legal_entity"]
    created_at = Timex.parse!(medication_request["created_at"], "{YYYY}-{0M}-{D}")

    response =
      medication_request
      |> Map.take(~w(
      id
      status
      request_number
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
      intent
      category
      context
      dosage_instruction
      rejected_at
      rejected_by
      reject_reason
    ))
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.into(%{})
      |> Map.merge(%{
        "legal_entity" => LegalEntitiesRenderer.render("show_reimbursement_details.json", legal_entity),
        "employee" => render("employee.json", medication_request["employee"]),
        "division" => render("division.json", medication_request["division"]),
        "medication_info" => render("medication_info.json", medication_request),
        "person" => render_person(medication_request["person"], created_at)
      })

    if Map.get(medication_request, "medical_program") do
      Map.put(response, "medical_program", render("medical_program.json", medication_request["medical_program"]))
    else
      response
    end
  end

  def render("employee.json", %Employee{} = employee) do
    party = Map.take(employee.party, ~w(
      id
      first_name
      last_name
      second_name
      phones
    )a)

    employee
    |> Map.take(~w(id position)a)
    |> Map.put(:party, party)
  end

  def render("division.json", %Division{} = division) do
    division
    |> Map.take(~w(
      id
      name
      type
      addresses
      phones
      email
      external_id
      legal_entity_id
      working_hours
    )a)
    |> Map.merge(%{
      location: to_coordinates(division.location),
      addresses: Enum.map(division.addresses, &DivisionsRenderer.render("division_addresses.json", &1))
    })
  end

  def render("medical_program.json", %MedicalProgram{} = medical_program) do
    Map.take(medical_program, ~w(id name)a)
  end

  def render("medication_info.json", medication_request) do
    medication = medication_request["medication"]
    ingredient = Enum.find(medication.ingredients, &Map.get(&1, :is_primary))

    medication_request
    |> Map.take(~w(medication_qty))
    |> Map.merge(%{
      "form" => medication.form,
      "medication_id" => medication.id,
      "medication_name" => medication.name,
      "dosage" => ingredient.dosage
    })
  end

  def render_person(%{birth_date: birth_date} = person, mrr_created_at) do
    response = PersonsRenderer.render("show.json", person)
    %{"id" => response.id, "age" => age(birth_date, mrr_created_at), "short_name" => initials(response)}
  end

  defp age(birth_date, current_date) do
    Timex.diff(current_date, birth_date, :years)
  end

  defp initials(%{first_name: first_name, last_name: last_name, second_name: second_name}) do
    last_name <> get_initials(first_name) <> get_initials(second_name)
  end

  defp get_initials(nil), do: ""
  defp get_initials(""), do: get_initials(nil)

  defp get_initials(name_part) do
    initials =
      name_part
      |> String.replace("-", " ")
      |> String.split(" ")
      |> Enum.filter(fn part -> String.length(part) > 0 end)
      |> Enum.map(&String.upcase/1)
      |> Enum.map(fn part -> String.first(part) <> "." end)
      |> Enum.join("-")

    if String.length(initials) > 0, do: " " <> initials, else: ""
  end

  defp to_coordinates(%Geo.Point{coordinates: {lng, lat}}) do
    %{
      longitude: lng,
      latitude: lat
    }
  end

  defp to_coordinates(field), do: field
end
