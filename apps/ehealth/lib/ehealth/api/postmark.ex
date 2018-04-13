defmodule EHealth.API.Postmark do
  @moduledoc false

  @behaviour EHealth.API.PostmarkBehaviour

  defp get_base_url, do: Confex.fetch_env!(:ehealth, EHealth.API.Postmark)[:endpoint]

  defp get_request_headers do
    [
      Accept: "application/json",
      "Content-Type": "application/json",
      "X-Postmark-Server-Token": Confex.fetch_env!(:ehealth, EHealth.Bamboo.PostmarkMailer)[:api_key]
    ]
  end

  defp get_bounces_endpoint(email), do: "#{get_base_url()}/bounces/?count=1&offset=0&emailFilter=#{email}"
  defp activate_bounce_endpoint(bounce_id), do: "#{get_base_url()}/bounces/#{bounce_id}/activate"

  @impl true
  def get_bounces(email) do
    email
    |> get_bounces_endpoint()
    |> HTTPoison.get(get_request_headers())
  end

  @impl true
  def activate_bounce(bounce_id) do
    bounce_id
    |> activate_bounce_endpoint()
    |> HTTPoison.put("", get_request_headers())
  end
end
