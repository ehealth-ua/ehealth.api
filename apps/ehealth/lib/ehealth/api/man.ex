defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  require Logger

  @behaviour EHealth.API.ManBehaviour

  @filter_headers ~w(content-length Content-Length api-key authorization accept-language content-type accept)

  def process_url(url), do: config()[:endpoint] <> url

  def render_template(id, data, headers \\ []) do
    path = "/templates/#{id}/actions/render"

    headers =
      headers
      |> Keyword.drop(@filter_headers)
      |> Kernel.++([{"content-type", "application/json"}])
      |> Kernel.++([{"accept", "text/html"}])

    processed_request_headers =
      Enum.reduce(headers, %{}, fn {k, v}, map ->
        Map.put_new(map, k, v)
      end)

    Logger.info(fn ->
      Poison.encode!(%{
        "log_type" => "microservice_request",
        "microservice" => config()[:endpoint],
        "action" => "POST",
        "path" => Enum.join([config()[:endpoint], path]),
        "request_id" => Logger.metadata()[:request_id],
        "body" => data,
        "headers" => processed_request_headers
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
