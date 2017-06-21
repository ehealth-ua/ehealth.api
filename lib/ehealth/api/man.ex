defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.Helpers.MicroserviceCallLog, as: CallLog

  require Logger

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def render_template(id, data, headers \\ []) do
    CallLog.log("POST", config()[:endpoint], "/templates/#{id}/actions/render", data, headers)

    "/templates/#{id}/actions/render"
    |> post!(Poison.encode!(data), headers, timeouts())
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
