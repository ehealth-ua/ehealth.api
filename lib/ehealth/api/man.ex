defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth

  @filter_headers ["content-length", "Content-Length"]

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def process_request_headers(headers) do
    headers
    |> Keyword.drop(@filter_headers)
    |> Kernel.++([{"Content-Type", "application/json"}])
  end

  def render_template(id, data, headers \\ []) do
    "/templates/#{id}/actions/render"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> Map.get(:body)
  end
end
