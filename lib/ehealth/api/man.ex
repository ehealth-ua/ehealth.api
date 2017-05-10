defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def render_template(id, data, headers \\ []) do
    "/templates/#{id}/actions/render"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> Map.get(:body)
  end
end
