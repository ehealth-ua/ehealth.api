defmodule Core.Log do
  @moduledoc false

  require Logger

  def error(message) when is_binary(message), do: error(%{"message" => message})
  def error(%{"message" => _} = log_data), do: do_log(Map.merge(%{"log_type" => "error"}, log_data), &Logger.error/1)

  def info(message) when is_binary(message), do: Logger.info(message)
  def info(%{"message" => _} = log_data), do: do_log(Map.merge(%{"log_type" => "info"}, log_data), &Logger.info/1)

  defp do_log(%{} = log_data, log_function) do
    log_function.(fn ->
      log_data
      |> Map.merge(%{"request_id" => Logger.metadata()[:request_id]})
      |> Jason.encode!()
    end)
  end
end
