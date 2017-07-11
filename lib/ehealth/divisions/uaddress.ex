defmodule EHealth.Divisions.UAddress do
  @moduledoc """
  Service layer for synchronous update of the UAddress settlement and divisions
  """
  use OkJose
  alias EHealth.API.PRM
  alias EHealth.API.UAddress
  import EHealth.Utils.Pipeline

  def update_settlement(%{"id" => id} = data, headers) do
    {:ok, %{id: id, update_data: data, headers: headers}}
    |> api_get_settlement()
    |> check_settlement_diff()
    |> api_update_settlement()
    |> api_update_divisions()
    |> rollback_settlement()
    |> ok()
    |> end_pipe()
  end

  defp api_get_settlement(%{id: id, headers: headers} = pipedata) do
    id
    |> UAddress.get_settlement_by_id(headers)
    |> put_success_api_response_in_pipe(:settlement, pipedata)
  end

  def check_settlement_diff(%{update_data: data, settlement: %{"data" => settlement}} = pipe_data) do
    settlement_set =
      settlement
      |> Map.take(Map.keys(data))
      |> MapSet.new()

    data
    |> MapSet.new()
    |> MapSet.difference(settlement_set)
    |> MapSet.to_list()
    |> Enum.into(%{})
    |> put_in_pipe(:update_data, pipe_data)
  end

  defp api_update_settlement(%{id: id, headers: headers, update_data: data} = pipedata) when map_size(data) > 0 do
    id
    |> UAddress.update_settlement(data, headers)
    |> put_success_api_response_in_pipe(:settlement_updated, pipedata)
  end
  defp api_update_settlement(pipe_data), do: pipe_data

  defp api_update_divisions(%{id: id, headers: headers, update_data: %{"mountain_group" => group}} = pipe_data) do
    %{settlement_id: id, mountain_group: group}
    |> PRM.update_divisions_mountain_group(headers)
    |> case do
         {:ok, _} -> {:ok, pipe_data}
         {:error, reason} -> put_in_pipe(reason, :division_update_error, pipe_data)
       end
  end
  defp api_update_divisions(pipe_data), do: pipe_data

  defp rollback_settlement(%{division_update_error: err, settlement: %{"data" => data}} = pipe_data) do
    UAddress.update_settlement(pipe_data.id, data, pipe_data.headers)
    {:error, err}
  end
  defp rollback_settlement(%{settlement_updated: settlement_updated} = pipe_data) do
    put_in_pipe(settlement_updated, :settlement, pipe_data)
  end
  defp rollback_settlement(pipe_data), do: pipe_data
end
