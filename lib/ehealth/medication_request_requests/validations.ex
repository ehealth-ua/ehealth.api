defmodule EHealth.MedicationRequestRequest.Validations do
  @moduledoc false

  alias EHealth.API.Signature
  alias EHealth.Employees
  alias EHealth.Validators.JsonSchema
  alias EHealth.Employees.Employee
  alias EHealth.Declarations.API, as: DeclarationsAPI
  alias EHealth.Medications

  def validate_create_schema(params) do
    JsonSchema.validate(:medication_request_request_create, params)
  end

  def validate_prequalify_schema(params) do
    JsonSchema.validate(:medication_request_request_prequalify, params)
  end

  def validate_sign_schema(params) do
    JsonSchema.validate(:medication_request_request_sign, params)
  end

  def validate_doctor(doctor, legal_entity) do
    with true <- doctor.employee_type == "DOCTOR",
         true <- doctor.status == "APPROVED",
         true <- doctor.legal_entity.id == legal_entity.id do
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

  def validate_divison(division, legal_entity_id) do
    with true <- division.is_active &&
                 division.status == "ACTIVE" &&
                 division.legal_entity_id == legal_entity_id
    do
      {:ok, division}
    else
      _ -> {:invalid_division, division}
    end
  end

  def validate_medication_id(medication_id, medication_qty, medical_program_id) do
    with medications <- Medications.get_medication_for_medication_request_request(medication_id, medical_program_id),
         {true, :medication} <- {length(medications) > 0, :medication},
         {true, :medication_qty} <- validate_medication_qty(medications, medication_qty)
     do
      {:ok, medications}
    else
      {false, :medication} -> {:invalid_medication, nil}
      {false, :medication_qty} -> {:invalid_medication_qty, nil}
    end
  end

  defp validate_medication_qty(medications, medication_qty) do
    {0 in Enum.map(medications, fn med -> rem(medication_qty, med.package_min_qty) end), :medication_qty}
  end

  def decode_sign_content(content, headers) do
    content["signed_medication_request_request"]
    |> Signature.decode_and_validate(content["signed_content_encoding"], headers)
    |> check_is_valid()
  end
  def check_is_valid({:ok, %{"data" => %{"is_valid" => false}}}) do
    {:error, {:bad_request, "Signed request data is invalid"}}
  end
  def check_is_valid({:ok, %{"data" => %{"is_valid" => true}}} = data), do: data
  def check_is_valid({:error, error}) do
    {:error, error}
  end

  def validate_sign_content(mrr, %{"content" => content, "signer" => signer}) do
    with %Employee{} = employee <- Employees.get_by_id(mrr.data.employee_id),
         doctor_tax_id          <- employee |> Map.get(:party) |> Map.get(:tax_id),
         true                   <- mrr.id == content["id"] &&
                                   mrr.data.division_id == get_in(content, ["division", "id"]) &&
                                   mrr.data.employee_id == get_in(content, ["employee", "id"]) &&
                                   mrr.data.legal_entity_id == get_in(content, ["legal_entity", "id"]) &&
                                   mrr.data.medication_id == get_in(content, ["medication_info", "medication_id"]) &&
                                   mrr.data.person_id == get_in(content, ["person", "id"]) &&
                                   doctor_tax_id == signer["drfo"]
    do
      {:ok, mrr}
    else
      _ -> {:error, {:"422", "Signed content does not match the previously created content!"}}
    end
  end

  def validate_dates(attrs) do
    cond do
      attrs["ended_at"] < attrs["started_at"] ->
        {:invalid_state, {:"ended_at", "Ended date must be >= Started date!"}}
      attrs["started_at"] < attrs["created_at"] ->
        {:invalid_state, {:"started_at", "Started date must be >= Created date!"}}
      attrs["started_at"] < to_string(Timex.today()) ->
        {:invalid_state, {:"started_at", "Started date must be >= Current date!"}}
      attrs["dispense_valid_from"] < attrs["started_at"] ->
        {:invalid_state, {:"dispense_valid_from", "Dispense valid from date must be >= Started date!"}}
      attrs["dispense_valid_to"] < attrs["dispense_valid_from"] ->
        {:invalid_state, {:"dispense_valid_from", "Dispense valid to date must be >= Dispense valid from date!"}}
      true ->  {:ok, nil}
    end
  end
end
