defmodule EHealth.Validators.SchemaMapper do
  @moduledoc """
  Load dictionaries from DB and put enum rules into json schema
  """

  alias EHealth.Dictionaries
  alias EHealth.Dictionaries.Dictionary
  alias NExJsonSchema.Schema.Root
  require Logger

  @validator_cache Application.get_env(:ehealth, :cache)[:validators]

  def prepare_schema(%Root{schema: schema} = nex_schema, schema_name) do
    case @validator_cache.get_json_schema(schema_name) do
      {:ok, nil} ->
        new_schema =
          %{"is_active" => true}
          |> Dictionaries.list_dictionaries()
          |> map_schema(schema)

        prepared_schema = %{nex_schema | schema: new_schema}
        @validator_cache.set_json_schema(schema_name, prepared_schema)
        prepared_schema

      {:ok, cached_schema} ->
        cached_schema

      _ ->
        {:error, {:internal_error, "can't validate json schema"}}
    end
  end

  def map_schema({:ok, dictionaries}, schema) when length(dictionaries) > 0 do
    Enum.reduce(schema, %{}, &process_schema_value(&1, &2, dictionaries))
  end

  def map_schema(_dictionaries, schema) do
    Logger.warn(fn -> "Empty dictionaries db" end)
    schema
  end

  defp process_schema_value({k, v}, acc, dictionaries) when is_map(v) do
    Map.put(acc, k, Enum.reduce(v, %{}, &process_schema_value(&1, &2, dictionaries)))
  end

  defp process_schema_value({k = "description", v}, acc, dictionaries) do
    acc = Map.put(acc, k, v)

    with %{"type" => type} <- Regex.named_captures(~r/Dictionary: (?<type>\w+)$/, v),
         %Dictionary{values: values} <- Enum.find(dictionaries, fn %Dictionary{name: name} -> name == type end) do
      Map.put(acc, "enum", Map.keys(values))
    else
      _ -> acc
    end
  end

  defp process_schema_value({k, v}, acc, _dictionaries) do
    Map.put(acc, k, v)
  end
end
