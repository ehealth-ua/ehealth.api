defmodule Core.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :core
  require Logger

  @behaviour Core.API.ManBehaviour

  @filter_headers ~w(content-length Content-Length api-key authorization accept-language content-type accept)

  def process_url(url), do: config()[:endpoint] <> url

  def render_template(id, data, headers) do
    path = "/templates/#{id}/actions/render"

    headers =
      headers
      |> Keyword.drop(@filter_headers)
      |> Kernel.++([{"content-type", "application/json"}])
      |> Kernel.++([{"accept", "text/html"}])

    Logger.info("Microservice POST request to #{config()[:endpoint]} on #{Enum.join([config()[:endpoint], path])}.
      Body: #{inspect(data)}")

    path
    |> post!(Jason.encode!(data), headers, config()[:hackney_options])
    |> process_template()
  end

  defp process_template(%HTTPoison.Response{body: body, status_code: 200}) do
    {:ok, body}
  end

  defp process_template(%HTTPoison.Response{body: body}) do
    Logger.error("Microservice #{config()[:endpoint]} response: #{body}")
    {:error, body}
  end
end
