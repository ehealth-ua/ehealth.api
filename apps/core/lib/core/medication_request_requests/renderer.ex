defmodule Core.MedicationRequestRequest.Renderer do
  @moduledoc false

  alias Core.Divisions.Renderer, as: DivisionsRenderer
  alias Core.Employees.Renderer, as: EmployeesRenderer
  alias Core.LegalEntities.Renderer, as: LegalEntitiesRenderer
  alias Core.MedicalPrograms.Renderer, as: MedicalProgramsRenderer
  alias Core.Medications.INNMDosage.Renderer, as: INNMDosageRenderer
  alias Core.Persons.Renderer, as: PersonsRenderer

  def render("medication_request_request_detail.json", mrr_data) do
    response =
      mrr_data.medication_request_request.data
      |> Map.take(~w(
      created_at
      started_at
      ended_at
      dispense_valid_from
      dispense_valid_to
      intent
      category
      context
      dosage_instruction
      )a)
      |> Enum.reject(fn {_, v} -> is_nil(v) end)
      |> Enum.into(%{})
      |> Map.merge(%{
        id: mrr_data.medication_request_request.id,
        person: render_person(mrr_data.person, mrr_data.medication_request_request.data.created_at),
        employee: EmployeesRenderer.render("employee_private.json", mrr_data.employee),
        legal_entity: LegalEntitiesRenderer.render("show_reimbursement.json", mrr_data.legal_entity),
        division: DivisionsRenderer.render("division.json", mrr_data.division),
        medication_info:
          INNMDosageRenderer.render(
            "innm_dosage_short.json",
            mrr_data.medication,
            mrr_data.medication_request_request.data.medication_qty
          ),
        request_number: mrr_data.medication_request_request.request_number,
        status: mrr_data.medication_request_request.status
      })

    if Map.get(mrr_data, :medical_program) do
      Map.put(response, :medical_program, MedicalProgramsRenderer.render("show.json", mrr_data.medical_program))
    else
      response
    end
  end

  def render_person(%{birth_date: birth_date} = person, mrr_created_at) do
    age = get_age(birth_date, mrr_created_at)
    response = PersonsRenderer.render("show.json", person)

    response
    |> Map.put("age", age)
    |> Map.drop(~w(birth_date addresses)a)
  end

  defp get_age(birth_date, current_date) do
    Timex.diff(current_date, birth_date, :years)
  end
end
