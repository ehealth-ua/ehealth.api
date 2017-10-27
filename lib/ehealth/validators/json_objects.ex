defmodule EHealth.Validators.JsonObjects do
@moduledoc """
  Additional validation for serialized JSON objects
  """

  def get_value_in(object, object_path) do
    case get_in(object, object_path) do
      nil -> {:error, [{get_error("Key not found"), get_path(object_path)}]}
      array -> {:ok, array}
    end
  end

  def array_unique_by_key(object, object_path, key_name, valid_keys) do
    with  {:ok, array} <- get_value_in(object, object_path),
          keys = get_keys(array, key_name),
          valid_keys = MapSet.new(valid_keys),
          :ok <- check_for_duplicate_keys(keys, valid_keys, MapSet.new, 0)
    do
      :ok
    else
      {:error, rules, i} -> {:error, [{rules, get_path(object_path, i, key_name)}]}
    end
  end

  defp check_for_duplicate_keys([], _, _, _), do: :ok
  defp check_for_duplicate_keys([h | t], valid_keys, validated_keys, i) do
    cond do
      not MapSet.member?(valid_keys, h) ->
        {:error, get_error("Value '#{h}' is not found in Dictionary.", MapSet.to_list(valid_keys)), i}
      MapSet.member?(validated_keys, h) ->
        {:error, get_error("No duplicate values.", h), i}
      true ->
        check_for_duplicate_keys(t, valid_keys, MapSet.put(validated_keys, h), i + 1)
    end
  end

  def array_single_item(object, object_path, key_name, valid_keys) do
   with  {:ok, array} <- get_value_in(object, object_path),
          keys = get_keys(array, key_name),
          :ok <- check_for_single_key(keys, valid_keys)
    do
      :ok
    else
      {:error, rules} -> {:error, [{rules, get_path(object_path, 0, key_name)}]}
    end
  end

  defp check_for_single_key([key], valid_keys) do
    if Enum.any?(valid_keys, &(&1 == key)) do
      :ok
    else
      {:error, get_error("Value '#{key}' is not found in Dictionary.", valid_keys)}
    end
  end
  defp check_for_single_key(_, valid_keys) do
    {:error, get_error("Must contain only one valid item.", valid_keys)}
  end

  def array_item_required(object, object_path, key_name, required_item) do
    with  {:ok, array} <- get_value_in(object, object_path),
        keys = get_keys(array, key_name),
        :ok <- check_required_item(keys, required_item)
    do
      :ok
    else
      {:error, rules} -> {:error, [{rules, get_path(object_path, "[]", key_name)}]}
    end
  end

  defp check_required_item(keys, required_item) do
    if Enum.any?(keys, &(&1 == required_item)) do
      :ok
    else
      {:error, get_error("Must contain required item.", required_item)}
    end
  end

  def get_keys(object, key_name) do
    Enum.map(object, &Map.fetch!(&1, key_name))
  end

  defp get_path(object_path), do: "$." <> Enum.join(object_path, ".")
  defp get_path(object_path, "[]", key_name), do: "$." <> Enum.join(object_path, ".") <> "[].#{key_name}"
  defp get_path(object_path, i, key_name) when is_integer(i), do:
    "$." <> Enum.join(object_path, ".") <> "[#{i}]" <> ".#{key_name}"

  def combine_path(prefix, path) when is_binary(prefix) and is_binary(path), do:
    String.replace(path, "$.", "$.#{prefix}.")

  def get_error(rule), do: [%{rule: rule}]
  def get_error(rule, params) when is_list(params), do: [%{rule: rule, params: params}]
  def get_error(rule, param) when is_binary(param), do: [%{rule: rule, params: [param]}]
end
