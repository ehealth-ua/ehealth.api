defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  require Logger

  @behaviour EHealth.API.ManBehaviour

  @filter_headers ["content-length", "Content-Length", "api-key", "authorization"]

  def process_url(url), do: config()[:endpoint] <> url

  def render_template(id, data, headers \\ []) do
    path = "/templates/#{id}/actions/render"

    headers =
      headers
      |> Keyword.drop(@filter_headers)
      |> Kernel.++([{"Content-Type", "application/json"}])

    Logger.info(fn ->
      Poison.encode!(%{
        "log_type" => "microservice_request",
        "microservice" => config()[:endpoint],
        "action" => "POST",
        "path" => Enum.join([config()[:endpoint], path]),
        "request_id" => Logger.metadata()[:request_id],
        "body" => data,
        "headers" => headers
      })
    end)

    path
    |> post!(Poison.encode!(data), headers, config()[:hackney_options])
    |> process_template()
  end

  defp process_template(%HTTPoison.Response{body: body, status_code: 200}) do
    {:ok, body}
  end

  defp process_template(%HTTPoison.Response{body: body}) do
    Logger.error(fn ->
      Poison.encode!(%{
        "log_type" => "microservice_response",
        "microservice" => config()[:endpoint],
        "response" => body,
        "request_id" => Logger.metadata()[:request_id]
      })
    end)

    {:error, body}
  end
end
