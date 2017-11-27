defmodule EHealth.Divisions.UAddress do
  @moduledoc """
  Service layer for synchronous update of the UAddress settlement and divisions
  """
  alias EHealth.API.UAddress
  alias EHealth.Divisions

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  def update_settlement(%{"id" => id} = params, headers) do
    with {:ok, data} <- prepare_settlement_data(params),
         {:ok, settlement} <- UAddress.get_settlement_by_id(id, headers),
         {:ok, settlement} <- api_update_settlement(data, headers, settlement)
    do
      {:ok, settlement}
    end
  end

  defp prepare_settlement_data(%{"id" => id, "settlement" => settlement}) do
    {:ok, Map.put(settlement, "id", id)}
  end
  defp prepare_settlement_data(_) do
    {:error, {:"422", "required property settlement was not present"}}
  end

  def update_required?(data, settlement) do
    settlement_set =
      settlement
      |> Map.take(Map.keys(data))
      |> MapSet.new()

    data
    |> MapSet.new()
    |> MapSet.difference(settlement_set)
    |> MapSet.to_list()
    |> Enum.empty?()
    |> Kernel.!()
  end

  defp api_update_settlement(%{"id" => id} = data, headers, settlement) do
    case update_required?(data, settlement) do
      true ->
        with {:ok, updated_settlement} <- UAddress.update_settlement(id, data, headers),
             :ok <- api_update_divisions(data, headers, settlement)
        do
          {:ok, updated_settlement}
        end
      false -> {:ok, settlement}
    end
  end

  defp api_update_divisions(%{"id" => id, "mountain_group" => group} = data, headers, settlement) do
    consumer_id = get_consumer_id(headers)
    result = Divisions.update_mountain_group(%{settlement_id: id, mountain_group: group}, consumer_id)
    case result do
      %Ecto.Changeset{valid?: false} -> result
      {:error, _failed_operation, failed_value, _changes_so_far} -> failed_value
      _ -> :ok
    end
  rescue
    _ -> rollback_settlement(data, headers, settlement, "Failed to update divisions mountain group")
  end
  defp api_update_divisions(_, _, _), do: :ok

  defp rollback_settlement(%{"id" => id}, headers, settlement, reason) do
    UAddress.update_settlement(id, settlement, headers)
    {:error, reason}
  end
end
