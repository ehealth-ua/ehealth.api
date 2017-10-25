defmodule EHealth.Validators.JsonObjects do
@moduledoc """
  Additional validation for serialized JSON objects
  """

  def array_unique_by_key(object, object_path, key_name, valid_keys) do
    with  {:ok, array} <- get_value_in(object, object_path),
          keys = get_keys(array, key_name),
          valid_keys = MapSet.new(valid_keys),
          :ok <- check_for_duplicate_keys(keys, valid_keys, MapSet.new)
    do
      :ok
    else
      {:error, reason} -> {:error, [{reason, get_path(object_path, key_name)}]}
    end
  end

  defp check_for_duplicate_keys([], _, _), do: :ok
  defp check_for_duplicate_keys([h | t], valid_keys, validated_keys) do
    cond do
      not MapSet.member?(valid_keys, h) -> {:error, "Value '#{h}' is not found in Dictionary"}
      MapSet.member?(validated_keys, h) -> {:error, "Duplicate value '#{h}'"}
      true ->                              check_for_duplicate_keys(t, valid_keys, MapSet.put(validated_keys, h))
    end
  end

  def array_single_valid_item(object, object_path, key_name, valid_keys) do
   with  {:ok, array} <- get_value_in(object, object_path),
          keys = get_keys(array, key_name),
          valid_keys = MapSet.new(valid_keys),
          :ok <- check_for_single_key(keys, valid_keys)
    do
      :ok
    else
      {:error, reason} -> {:error, [{reason, get_path(object_path, key_name)}]}
    end
  end

  defp check_for_single_key([key], valid_keys) do
    if Enum.any?(valid_keys, &(&1 == key)) do
      :ok
    else
      {:error, "Value '#{key}' is not found in Dictionary"}
    end
  end

  defp check_for_single_key(_, _) do
    {:error, "More than one value found!"}
  end

  def get_value_in(object, object_path) do
    case get_in(object, object_path) do
      nil -> {:error, [{"Key not found", get_path(object_path)}]}
      array -> {:ok, array}
    end
  end

  def array_contains_item(object, object_path, key_name, required_item) do
    with  {:ok, array} <- get_value_in(object, object_path),
        keys = get_keys(array, key_name),
        :ok <- check_required_item(keys, required_item)
    do
      :ok
    else
      {:error, reason} -> {:error, [{reason, get_path(object_path, key_name)}]}
    end
  end

  defp check_required_item(keys, required_item) do
    if Enum.any?(keys, &(&1 == required_item)) do
      :ok
    else
      {:error, "'#{required_item}' is required"}
    end
  end

  def get_keys(object, key_name) do
    Enum.map(object, &Map.fetch!(&1, key_name))
  end

  defp get_path(object_path), do: "#/" <> Enum.join(object_path, "/")
  defp get_path(object_path, key_name), do: "#/" <> Enum.join(object_path, "/") <> "/#{key_name}"
end
