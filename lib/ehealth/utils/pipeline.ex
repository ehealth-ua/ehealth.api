defmodule EHealth.Utils.Pipeline do
  @moduledoc """
  Pipeline builder
  """

  require Logger

  def put_in_pipe(data, key, pipe_data) do
    {:ok, Map.put(pipe_data, key, data)}
  end

  def put_success_api_response_in_pipe({:ok, resp}, key, pipe_data) do
    put_in_pipe(resp, key, pipe_data)
  end
  def put_success_api_response_in_pipe(err, _key, _pipe_data), do: err

  def validate_api_response({:ok, _}, pipe_data, _log_message), do: {:ok, pipe_data}
  def validate_api_response(err, _pipe_data, log_message) do
    Logger.error(fn -> log_message <> " Response: #{inspect err}" end)
    err
  end
end
