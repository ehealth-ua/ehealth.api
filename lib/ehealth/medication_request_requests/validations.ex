defmodule EHealth.MedicationRequestRequest.Validations do
  @moduledoc false

  alias EHealth.Declarations.API, as: DeclarationsAPI
  alias EHealth.Validators.JsonSchema

  def validate_schema(params) do
    JsonSchema.validate(:medication_request_request, params)
  end

  def validate_doctor(doctor) do
    with true <- doctor.employee_type == "DOCTOR",
         true <- doctor.status == "APPROVED" do
      {:ok, doctor}
    else
      _ -> {:invalid_employee, doctor}
    end
  end

  def validate_person(person) do
    with true <- person["is_active"] do
      {:ok, person}
    else
      _ -> {:invalid_person, person}
    end
  end

  def validate_declaration_existance(employee, person) do
    with {:ok, %{"data" => declarations}} <- DeclarationsAPI.get_declarations(%{"employee_id" => employee.id,
                                                            "person_id" => person["id"], "status" => "active"}, []),
         true <- length(declarations) > 0
    do
         {:ok, declarations}
    else
      _ -> {:invalid_declarations_count, nil}
    end
  end

  def validate_divison(division, legal_entity_id, employee) do
    with true <- division.is_active &&
                 division.status == "ACTIVE" &&
                 division.legal_entity_id == legal_entity_id &&
                 division.id == employee.division_id
    do
      {:ok, division}
    else
      _ -> {:invalid_division, division}
    end
  end

  def validate_medical_program(nil), do: {:ok, nil}
  def validate_medical_program(_medical_program_id) do
    {:ok, nil}
  end

  def validate_dates(attrs) do
    cond do
      attrs["ended_at"] < attrs["started_at"] -> {:invalid_state, "Ended date must be >= Started date!"}
      attrs["started_at"] < attrs["created_at"] -> {:invalid_state, "Started date must be >= Created date!"}
      attrs["started_at"] < Timex.today() -> {:invalid_state, "Started date must be >= Current date!"}
      true ->  {:ok, nil}
    end
  end
end
