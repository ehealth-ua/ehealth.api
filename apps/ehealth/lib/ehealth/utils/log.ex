defmodule EHealth.Utils.Log do
  @moduledoc false

  require Logger

  def error(%{"message" => _} = log_data), do: do_log(Map.merge(%{"log_type" => "error"}, log_data))

  defp do_log(%{} = log_data) do
    Logger.error(fn ->
      log_data
      |> Map.merge(%{"request_id" => Logger.metadata()[:request_id]})
      |> Poison.encode!()
    end)
  end
end
