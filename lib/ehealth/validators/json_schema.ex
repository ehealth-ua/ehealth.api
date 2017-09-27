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

  def validate(:innm_dosage = schema, attrs) do
    do_validate(schema, :prepare_innm_dosage_schema, attrs)
  end
  def validate(:medication = schema, attrs) do
    do_validate(schema, :prepare_medication_schema, attrs)
  end
  def validate(:legal_entity = schema, attrs) do
    do_validate(schema, :prepare_legal_entity_schema, attrs)
  end
  def validate(:declaration_request = schema, attrs) do
    do_validate(schema, :prepare_declaration_request_schema, attrs)
  end
  def validate(:division = schema, attrs) do
    do_validate(schema, :prepare_divisions_schema, attrs)
  end
  def validate(:employee_request = schema, attrs) do
    do_validate(schema, :prepare_employee_request_schema, attrs)
  end
  def validate(schema, attrs) when schema in [:employee_doctor, :employee_pharmacist] do
    do_validate(schema, :prepare_employee_additional_info_schema, attrs)
  end
  def validate(schema_name, attrs) do
    @schemas
    |> Keyword.get(schema_name)
    |> validate_schema(attrs)
  end

  defp do_validate(schema_name, validator, attrs) do
    SchemaMapper
    |> apply(validator, [Keyword.get(@schemas, schema_name)])
    |> validate_schema(attrs)
  end
end
