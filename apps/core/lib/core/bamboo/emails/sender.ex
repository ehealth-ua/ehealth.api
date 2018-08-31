defmodule Core.Bamboo.Emails.Sender do
  @moduledoc false

  use Confex, otp_app: :core
  import Bamboo.Email

  alias Core.Email.Postmark
  alias Core.Log

  def send_email(to, body, from, subject) do
    new_email()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> html_body(body)
    |> config()[:mailer].deliver_now()
  end

  def send_email_with_activation(to, body, from, subject, attempts \\ 2) do
    attempts = attempts - 1

    try do
      mail_entity = send_email(to, body, from, subject)
      {:ok, mail_entity}
    rescue
      err ->
        Log.error(%{"message" => "[#{__MODULE__}] Failed to send email with error: #{inspect(err)}"})

        with true <- should_activate_email?(err, attempts),
             {:ok, _} <- Postmark.activate_email(to) do
          send_email_with_activation(to, body, from, subject, attempts)
        else
          _ -> {:error, {:internal_error, "Failed to send email"}}
        end
    end
  end

  defp should_activate_email?(%Bamboo.PostmarkAdapter.ApiError{}, attempts) when attempts > 0, do: true
  defp should_activate_email?(_, _), do: false
end
