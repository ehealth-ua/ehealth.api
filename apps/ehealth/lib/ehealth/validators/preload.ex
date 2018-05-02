defmodule EHealth.Validators.Preload do
  @moduledoc false

  alias EHealth.Validators.Reference

  def preload_references(%{} = item, fields) do
    fields
    |> Enum.reduce(%{}, &get_reference_id(item, &1, &2))
    |> Enum.into(%{}, fn {type, ids} ->
      {type,
       Enum.into(ids, %{}, fn id ->
         with {:ok, value} <- Reference.validate(type, id) do
           {id, value}
         else
           _ -> {id, nil}
         end
       end)}
    end)
  end

  defp get_reference_id(item, {field_path, type}, acc) when is_atom(field_path) or is_binary(field_path) do
    do_get_reference_id(item, field_path, type, acc)
  end

  defp get_reference_id(item, {[field_path], type}, acc) when is_atom(field_path) or is_binary(field_path) do
    do_get_reference_id(item, field_path, type, acc)
  end

  defp get_reference_id(item, {field_path, type}, acc) when is_list(field_path) do
    [path | tail_path] = field_path

    case path do
      "$" ->
        Enum.reduce(item, acc, fn list_item, acc ->
          get_reference_id(list_item, {tail_path, type}, acc)
        end)

      _ ->
        get_reference_id(Map.get(item, path), {tail_path, type}, acc)
    end
  end

  defp do_get_reference_id(item, field_path, type, acc) do
    reference_id = Map.get(item, field_path)
    ids = Map.get(acc, type) || []
    ids = if Enum.member?(ids, reference_id) || is_nil(reference_id), do: ids, else: [reference_id | ids]
    Map.put(acc, type, ids)
  end
end
