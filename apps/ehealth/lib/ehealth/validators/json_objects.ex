defmodule EHealth.Validators.JsonObjects do
  @moduledoc """
  Additional validation for serialized JSON objects
  """

  alias EHealth.ValidationError

  def get_value_in(object, object_path) do
    case get_in(object, object_path) do
      nil -> %ValidationError{description: "Key not found", path: get_path(object_path)}
      array -> {:ok, array}
    end
  end

  def array_unique_by_key(object, object_path, key_name) do
    with {:ok, array} <- get_value_in(object, object_path),
         keys <- get_keys(array, key_name),
         :ok <- check_for_duplicate_keys(keys, MapSet.new(), object_path, key_name, 0) do
      :ok
    end
  end

  defp check_for_duplicate_keys([], _, _, _, _), do: :ok

  defp check_for_duplicate_keys([h | t], validated_keys, object_path, key_name, i) do
    if MapSet.member?(validated_keys, h) do
      %ValidationError{
        description: "No duplicate values.",
        params: [h],
        path: get_path(object_path, i, key_name)
      }
    else
      check_for_duplicate_keys(t, MapSet.put(validated_keys, h), object_path, key_name, i + 1)
    end
  end

  def array_single_item(object, object_path, key_name) do
    with {:ok, array} <- get_value_in(object, object_path),
         keys <- get_keys(array, key_name),
         :ok <- check_for_single_key(keys, object_path, key_name) do
      :ok
    end
  end

  defp check_for_single_key([_], _, _), do: :ok

  defp check_for_single_key(_, object_path, key_name) do
    %ValidationError{
      description: "Must contain only one valid item.",
      path: get_path(object_path, 0, key_name)
    }
  end

  def array_item_required(object, object_path, key_name, required_item) do
    with {:ok, array} <- get_value_in(object, object_path),
         keys <- get_keys(array, key_name),
         :ok <- check_required_item(keys, required_item, object_path, key_name) do
      :ok
    end
  end

  defp check_required_item(keys, required_item, object_path, key_name) do
    if Enum.any?(keys, &(&1 == required_item)) do
      :ok
    else
      %ValidationError{
        description: "Must contain required item.",
        path: get_path(object_path, "[]", key_name),
        params: [required_item]
      }
    end
  end

  def get_keys(object, key_name) do
    Enum.map(object, &Map.fetch!(&1, key_name))
  end

  defp get_path(object_path), do: "$." <> Enum.join(object_path, ".")
  defp get_path(object_path, "[]", key_name), do: "$." <> Enum.join(object_path, ".") <> "[].#{key_name}"

  defp get_path(object_path, i, key_name) when is_integer(i),
    do: "$." <> Enum.join(object_path, ".") <> "[#{i}]" <> ".#{key_name}"

  def combine_path(prefix, path) when is_binary(prefix) and is_binary(path),
    do: String.replace(path, "$.", "$.#{prefix}.")
end
