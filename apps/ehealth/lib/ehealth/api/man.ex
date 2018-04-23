defmodule EHealth.API.Man do
  @moduledoc """
  Man API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.Helpers.MicroserviceBase
  require Logger

  @behaviour EHealth.API.ManBehaviour

  def render_template(id, data, headers \\ []) do
    path = "/templates/#{id}/actions/render"

    path
    |> post!(Poison.encode!(data), headers)
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
