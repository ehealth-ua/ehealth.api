defmodule EHealth.API.Helpers.MicroserviceCallLog do
  @moduledoc false

  require Logger

  def log(method, endpoint, path, headers) do
    log_string = fn ->
      "Calling #{method} on #{endpoint}#{path} with headers=#{inspect headers}."
    end

    Logger.info(log_string)
  end

  def log(method, endpoint, path, body, headers) do
    log_string = fn ->
      "Calling #{method} on #{endpoint}#{path} with body=#{inspect body} and headers=#{inspect headers}."
    end

    Logger.info(log_string)
  end
end
