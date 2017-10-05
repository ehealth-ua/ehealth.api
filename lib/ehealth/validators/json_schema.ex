defmodule EHealth.Validators.JsonSchema do
  @moduledoc """
  Validates JSON schema
  """

  use JValid
  alias EHealth.Validators.SchemaMapper

  use_schema :medication_request_request, "specs/json_schemas/new_medication_request_request_schema.json"
  use_schema :medication_dispense, "specs/json_schemas/new_medication_dispense_request_schema.json"
  use_schema :declaration_request, "specs/json_schemas/declaration_request_schema.json"
  use_schema :division, "specs/json_schemas/division_schema.json"
  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"
  use_schema :employee_doctor, "specs/json_schemas/employee_doctor_schema.json"
  use_schema :employee_pharmacist, "specs/json_schemas/employee_pharmacist_schema.json"
  use_schema :legal_entity, "specs/json_schemas/new_legal_entity_schema.json"
  use_schema :innm, "specs/json_schemas/new_innm_schema.json"
  use_schema :medication, "specs/json_schemas/new_medication_schema.json"
  use_schema :innm_dosage, "specs/json_schemas/new_innm_dosage_schema.json"
  use_schema :program_medication, "specs/json_schemas/program_medications_create_request.json"
  use_schema :program_medication_update, "specs/json_schemas/program_medications_update_request.json"

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
