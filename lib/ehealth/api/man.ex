defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor
  require Logger

  def process_url(url), do: config()[:endpoint] <> url

  def render_template(id, data, headers \\ []) do
    path = "/templates/#{id}/actions/render"
    Logger.info(fn ->
      "Calling POST on #{config()[:endpoint]}#{path} with body=#{inspect data} and headers=#{inspect headers}."
    end)

    path
    |> post!(Poison.encode!(data), headers, config()[:hackney_options])
    |> process_template()
  end

  defp process_template(%HTTPoison.Response{body: body, status_code: 200}) do
    {:ok, body}
  end

  defp process_template(%HTTPoison.Response{body: body}) do
    Logger.error(fn -> "Error during Man interaction. Result from Man: #{inspect body}" end)

    {:error, body}
  end
end
