defmodule Core.Email.Postmark do
  @moduledoc false

  require Logger

  @postmark Application.get_env(:core, :api_resolvers)[:postmark]

  @spec activate_email(binary) :: {:ok, binary} | {:error, binary}
  def activate_email(email) do
    Logger.info("[PostmarkClient]: Attempting to activate #{email}")

    with {:ok, bounce_id} <- get_bounce_id(email),
         {:ok, _} <- activate_bounce(bounce_id) do
      Logger.info("[PostmarkClient]: Email '#{email}' was activated")

      {:ok, bounce_id}
    else
      {:error, error} = error_result ->
        Logger.error("[PostmarkClient]: #{error}")
        error_result

      error ->
        Logger.error("[PostmarkClient]: error happened #{inspect(error)}")
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
    Logger.error("[PostmarkClient]: postmark api error with reason '#{reason}'")
    %{}
  end

  defp parse_response_body(error) do
    Logger.error("[PostmarkClient]: postmark api error: '#{inspect(error)}'")
    %{}
  end
end
