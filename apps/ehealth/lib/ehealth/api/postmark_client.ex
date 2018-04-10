defmodule EHealth.API.PostmarkClient do
  @moduledoc false

  @behaviour EHealth.API.PostmarkClientBehaviour

  @base_url "https://api.postmarkapp.com"
  @get_bounces_endpoint @base_url <> "/bounces/?count=1&offset=0&emailFilter={email}"
  @activate_bounce_endpoint @base_url <> "/bounces/{bounce_id}/activate"

  @headers [
    Accept: "application/json",
    "Content-Type": "application/json",
    "X-Postmark-Server-Token": Confex.fetch_env!(:ehealth, EHealth.Bamboo.PostmarkMailer)[:api_key]
  ]

  @impl true
  @spec activate_email(binary) :: {:ok, binary} | {:error, binary}
  def activate_email(email) do
    email
    |> get_bounce_id()
    |> activate_bounce()
  end

  defp get_bounce_id(email) do
    @get_bounces_endpoint
    |> String.replace("{email}", email)
    |> HTTPoison.get(@headers)
    |> parse_response_body()
    |> case do
      %{"TotalCount" => 0} ->
        {:error, "bounce not found"}

      %{"Bounces" => [bounce | _]} ->
        bounce_id = bounce |> Map.get("ID") |> Integer.to_string()
        {:ok, bounce_id}
    end
  end

  defp activate_bounce({:ok, bounce_id}) do
    @activate_bounce_endpoint
    |> String.replace("{bounce_id}", bounce_id)
    |> HTTPoison.put("", @headers)
    |> parse_response_body()
    |> case do
      %{"Bounce" => %{"CanActivate" => true}} -> {:ok, bounce_id}
      _ -> {:error, "can not activate email"}
    end
  end

  defp activate_bounce({:error, _}) do
    {:error, "can not activate email"}
  end

  defp parse_response_body({:ok, response}) do
    response
    |> Map.get(:body)
    |> Poison.decode!()
  end

  defp parse_response_body(_), do: %{}
end
