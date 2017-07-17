defmodule EHealth.Divisions.UAddress do
  @moduledoc """
  Service layer for synchronous update of the UAddress settlement and divisions
  """
  alias EHealth.API.PRM
  alias EHealth.API.UAddress

  def update_settlement(%{"id" => id} = data, headers) do
    with {:ok, settlement} <- UAddress.get_settlement_by_id(id, headers),
         {:ok, settlement} <- api_update_settlement(data, headers, settlement)
    do
      {:ok, settlement}
    end
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
    %{settlement_id: id, mountain_group: group}
    |> PRM.update_divisions_mountain_group(headers)
    |> case do
         {:ok, _} -> :ok
         {:error, reason} -> rollback_settlement(data, headers, settlement, reason)
       end
  end
  defp api_update_divisions(_, _, _), do: :ok

  defp rollback_settlement(%{"id" => id}, headers, settlement, reason) do
    UAddress.update_settlement(id, settlement, headers)
    {:error, reason}
  end
end
