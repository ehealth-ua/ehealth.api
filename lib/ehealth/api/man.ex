defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  require Logger

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def render_template(id, data, headers \\ []) do
    "/templates/#{id}/actions/render"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> process_template()
  end

  def process_template(%HTTPoison.Response{body: body, status_code: 200}), do: body
  def process_template(response) do
    Logger.error(fn -> "Employee request invitation email template can not be rendered. Response: #{inspect response}" end)
    nil
  end
end
