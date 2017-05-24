defmodule EHealth.Utils.ValidationSchemaMapper do
  @moduledoc """
  Load dictionaries from DB and put enum rules into json schema
  """

  alias NExJsonSchema.Schema.Root
  alias EHealth.Dictionaries
  alias EHealth.Dictionaries.Dictionary

  require Logger

  def prepare_legal_entity_schema(%Root{schema: schema} = nex_schema) do
    schema = map_schema(Dictionaries.list_dictionaries(%{"is_active" => true}), :legal_entity, schema)

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

  def put_dictionary_value(%Dictionary{name: "PHONE_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "phone", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "DOCUMENT_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "document", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "ADDRESS_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "phone", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "COUNTRY", values: values}, schema, :legal_entity) do
    values = Map.keys(values)
    schema =
      schema
      |> put_in(["definitions", "education", "properties", "country", "enum"], values)
      |> put_in(["definitions", "science_degree", "properties", "country", "enum"], values)
    {nil, schema}
  end

  def put_dictionary_value(%Dictionary{name: "EDUCATION_DEGREE", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "education", "properties", "degree", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "QUALIFICATION_TYPE", values: values}, schema, :legal_entity) do
    values = Map.keys(values)
    schema =
      schema
      |> put_in(["definitions", "qualification", "properties", "type", "enum"], values)
      |> put_in(["definitions", "speciality", "properties", "qualification_type", "enum"], values)
    {nil, schema}
  end

  def put_dictionary_value(%Dictionary{name: "SPECIALITY_TYPE", values: values}, schema, :legal_entity) do
    values = Map.keys(values)
    schema =
      schema
      |> put_in(["definitions", "speciality", "properties", "speciality", "enum"], values)
      |> put_in(["definitions", "science_degree", "properties", "speciality", "enum"], values)
    {nil, schema}
  end

  def put_dictionary_value(%Dictionary{name: "SPECIALITY_LEVEL", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "speciality", "properties", "level", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "SCIENCE_DEGREE", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "phone", "properties", "type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "GENDER", values: values}, schema, :legal_entity) do
    put_into_schema(["definitions", "party", "properties", "gender", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: "EMPLOYEE_TYPE", values: values}, schema, :legal_entity) do
    put_into_schema(["properties", "employee_request", "properties", "employee_type", "enum"], schema, values)
  end

  def put_dictionary_value(%Dictionary{name: name}, schema, _type) do
    Logger.warn(fn -> "Dictionary with name #{name} is not mapped" end)
    {nil, schema}
  end

  def put_into_schema(path, schema, values) do
    {nil, put_in(schema, path, Map.keys(values))}
  end

end
