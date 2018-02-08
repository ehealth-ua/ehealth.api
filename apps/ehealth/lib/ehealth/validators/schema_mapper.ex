defmodule EHealth.Validators.SchemaMapper do
  @moduledoc """
  Load dictionaries from DB and put enum rules into json schema
  """

  alias NExJsonSchema.Schema.Root
  alias EHealth.Dictionaries
  alias EHealth.Dictionaries.Dictionary

  require Logger

  def prepare_schema(%Root{schema: schema} = nex_schema, type) do
    schema =
      %{"is_active" => true}
      |> Dictionaries.list_dictionaries()
      |> map_schema(type, schema)

    Map.put(nex_schema, :schema, schema)
  end

  def map_schema({:ok, dictionaries}, type, schema) when length(dictionaries) > 0 do
    dictionaries
    |> Enum.map_reduce(schema, &put_dictionary_value(&1, &2, type))
    |> elem(1)
  end

  def map_schema(_dictionaries, _type, schema) do
    Logger.warn(fn -> "Empty dictionaries db" end)
    schema
  end

  def put_dictionary_value(%Dictionary{name: "PHONE_TYPE", values: values}, schema, type)
      when type in [:legal_entity, :employee_request, :declaration_request] do
    put_into_schema(["definitions", "phone", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "DOCUMENT_TYPE", values: values}, schema, type)
      when type in [:legal_entity, :employee_request, :declaration_request] do
    put_into_schema(["definitions", "document", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(
        %Dictionary{name: "DOCUMENT_RELATIONSHIP_TYPE", values: values},
        schema,
        :declaration_request
      ) do
    put_into_schema(["definitions", "document_relationship", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "ADDRESS_TYPE", values: values}, schema, type)
      when type in [:legal_entity, :division, :declaration_request] do
    put_into_schema(["definitions", "address", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "GENDER", values: values}, schema, type)
      when type in [:legal_entity, :declaration_request, :employee_request] do
    put_into_schema(~W(definitions gender enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "OWNER_PROPERTY_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "owner_property_type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "LEGAL_ENTITY_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "LEGAL_FORM", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "legal_form", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "GENDER", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "owner", "properties", "gender", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "ACCREDITATION_CATEGORY", values: values}, schema, :legal_entity) do
    path = ["properties", "medical_service_provider", "properties", "accreditation", "properties", "category", "enum"]
    put_into_schema(path, schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "COUNTRY", values: values}, schema, :medication) do
    put_into_schema(~W(definitions manufacturer_object properties country enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "COUNTRY", values: values}, schema, :employee_request) do
    values = Map.keys(values)

    schema =
      schema
      |> put_in(["definitions", "education", "properties", "country", "enum"], values)
      |> put_in(["definitions", "science_degree", "properties", "country", "enum"], values)

    {nil, schema}
  end

  def put_dictionary_value(%Dictionary{name: "EDUCATION_DEGREE", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "education", "properties", "degree", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "QUALIFICATION_TYPE", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "qualification", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "SPEC_QUALIFICATION_TYPE", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "speciality", "properties", "qualification_type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "SPECIALITY_TYPE", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "speciality", "properties", "speciality", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "SPECIALITY_LEVEL", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "speciality", "properties", "level", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "SCIENCE_DEGREE", values: values}, schema, :employee_request) do
    put_into_schema(~W(definitions science_degree properties degree enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "GENDER", values: values}, schema, :employee_request) do
    put_into_schema(["definitions", "party", "properties", "gender", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "EMPLOYEE_TYPE", values: values}, schema, :employee_request) do
    put_into_schema(["properties", "employee_request", "properties", "employee_type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "POSITION", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "owner", "properties", "position", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "POSITION", values: values}, schema, :employee_request) do
    put_into_schema(["properties", "employee_request", "properties", "position", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "AUTHENTICATION_METHOD", values: values}, schema, :declaration_request) do
    put_into_schema(~W(definitions authentication_method properties type enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "MEDICATION_FORM", values: values}, schema, type)
      when type in [:medication, :innm_dosage] do
    put_into_schema(~W(properties form enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "REIMBURSEMENT_TYPE", values: values}, schema, :program_medication) do
    put_into_schema(~W(properties reimbursement properties type enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "REGISTER_TYPE", values: values}, schema, :registers) do
    put_into_schema(~W(properties type enum), schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "MEDICATION_UNIT", values: values}, schema, type)
      when type in [:medication, :innm_dosage] do
    values = Map.keys(values)

    schema =
      schema
      |> put_in(~W(definitions dosage_object properties numerator_unit enum), values)
      |> put_in(~W(definitions dosage_object properties denumerator_unit enum), values)

    {nil, schema}
  end

  def put_dictionary_value(%Dictionary{}, schema, _type) do
    {nil, schema}
  end

  def put_into_schema(path, schema, values) do
    {nil, put_in(schema, path, Map.keys(values))}
  end
end
