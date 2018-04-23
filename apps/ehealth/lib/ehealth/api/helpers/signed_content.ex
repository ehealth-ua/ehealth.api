defmodule EHealth.API.Helpers.SignedContent do
  @moduledoc """
  Save signed content by absolute url
  """

  require Logger

  use HTTPoison.Base

  def save(url, content, headers, options) do
    Logger.info(fn ->
      Poison.encode!(%{
        "log_type" => "http_request",
        "action" => "PUT",
        "path" => url,
        "request_id" => Logger.metadata()[:request_id],
        "body" => "[REDACTED]",
        "headers" => Enum.reduce(headers, %{}, fn {k, v}, map -> Map.put_new(map, k, v) end)
      })
    end)

    put!(url, content, headers, options)
  end
end
