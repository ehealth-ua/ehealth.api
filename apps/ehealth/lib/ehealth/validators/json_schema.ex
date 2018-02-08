defmodule EHealth.Validators.JsonSchema do
  @moduledoc """
  Validates JSON schema
  """

  use JValid
  alias EHealth.Validators.SchemaMapper

  use_schema(
    :medication_request_request_create,
    "specs/json_schemas/medication_request_request/medication_request_request_create_request.json"
  )

  use_schema(
    :medication_request_request_prequalify,
    "specs/json_schemas/medication_request_request/medication_request_request_prequalify_request.json"
  )

  use_schema(
    :medication_request_request_sign,
    "specs/json_schemas/medication_request_request/medication_request_request_sign_request.json"
  )

  use_schema(:medication_dispense, "specs/json_schemas/medication_dispense/medication_dispense_create_request.json")
  use_schema(:medical_program, "specs/json_schemas/medical_program/medical_program_create_request.json")
  use_schema(:declaration_request, "specs/json_schemas/declaration_request/declaration_request_create_request.json")
  use_schema(:division, "specs/json_schemas/division/division_create_request.json")
  use_schema(:employee_request, "specs/json_schemas/employee_request/employee_request_create_request.json")
  use_schema(:employee_doctor, "specs/json_schemas/employee/employee_doctor_create_request.json")
  use_schema(:employee_pharmacist, "specs/json_schemas/employee/employee_pharmacist_create_request.json")
  use_schema(:legal_entity, "specs/json_schemas/legal_entity/legal_entity_create_request.json")
  use_schema(:innm, "specs/json_schemas/innm/innm_create_request.json")
  use_schema(:medication, "specs/json_schemas/medication/medication_create_request.json")
  use_schema(:innm_dosage, "specs/json_schemas/innm_dosage/innm_dosage_create_request.json")
  use_schema(:program_medication, "specs/json_schemas/program_medication/program_medication_create_request.json")
  use_schema(:program_medication_update, "specs/json_schemas/program_medication/program_medication_update_request.json")
  use_schema(:registers, "specs/json_schemas/registers/registers_create_request.json")

  use_schema(
    :medication_request_qualify,
    "specs/json_schemas/medication_request/medication_request_qualify_request.json"
  )

  @schemas_with_dictionaries [
    :legal_entity,
    :innm_dosage,
    :medication,
    :declaration_request,
    :division,
    :employee_request
  ]

  def validate(schema, attrs) when schema in @schemas_with_dictionaries do
    validate_with_dictionaries(schema, schema, attrs)
  end

  def validate(schema, attrs) when schema in [:employee_doctor, :employee_pharmacist] do
    validate_with_dictionaries(schema, :employee_additional_info, attrs)
  end

  def validate(schema, attrs) when schema in [:program_medication, :program_medication_update] do
    validate_with_dictionaries(schema, :program_medication, attrs)
  end

  def validate(schema_name, attrs) do
    @schemas
    |> Keyword.get(schema_name)
    |> validate_schema(attrs)
  end

  defp validate_with_dictionaries(schema_name, type, attrs) do
    @schemas
    |> Keyword.get(schema_name)
    |> SchemaMapper.prepare_schema(type)
    |> validate_schema(attrs)
  end
end
