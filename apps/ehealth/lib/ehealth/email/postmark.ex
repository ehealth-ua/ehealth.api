defmodule EHealth.Email.Postmark do
  @moduledoc false

  alias Core.Log

  @postmark Application.get_env(:ehealth, :api_resolvers)[:postmark]

  @spec activate_email(binary) :: {:ok, binary} | {:error, binary}
  def activate_email(email) do
    Log.info("[PostmarkClient]: Attempting to activate #{email}")

    with {:ok, bounce_id} <- get_bounce_id(email),
         {:ok, _} <- activate_bounce(bounce_id) do
      Log.info("[PostmarkClient]: Email '#{email}' was activated")

      {:ok, bounce_id}
    else
      {:error, error} = error_result ->
        Log.error(%{"message" => "[PostmarkClient]: #{error}"})
        error_result

      error ->
        Log.error(%{"message" => "[PostmarkClient]: error happened #{inspect(error)}"})
        error
    end
  end

  defp get_bounce_id(email) do
    email
    |> @postmark.get_bounces()
    |> parse_response_body()
    |> case do
      %{"Bounces" => [%{"ID" => bounce_id} | _]} -> {:ok, Integer.to_string(bounce_id)}
      _ -> {:error, "bounce from '#{email}' not found"}
    end
  end

  defp activate_bounce(bounce_id) do
    bounce_id
    |> @postmark.activate_bounce()
    |> parse_response_body()
    |> case do
      %{"Bounce" => %{"CanActivate" => true}} -> {:ok, bounce_id}
      _ -> {:error, "can not activate email by bounce_id #{bounce_id}"}
    end
  end

  defp parse_response_body({:ok, %{status_code: 200, body: body}}) do
    case Jason.decode(body) do
      {:ok, result} -> result
      _ -> %{}
    end
  end

  defp parse_response_body({:error, %HTTPoison.Error{reason: reason}}) do
    Log.error(%{"message" => "[PostmarkClient]: postmark api error with reason '#{reason}'"})
    %{}
  end

  defp parse_response_body(error) do
    Log.error(%{"message" => "[PostmarkClient]: postmark api error: '#{inspect(error)}'"})
    %{}
  end
end
