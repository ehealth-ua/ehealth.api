defmodule Core.Bamboo.Emails.Sender do
  @moduledoc false

  use Confex, otp_app: :core
  import Bamboo.Email

  alias Core.Email.Postmark
  require Logger

  def send_email(to, body, from, subject) do
    new_email()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> html_body(body)
    |> config()[:mailer].deliver_now()
  end

  def send_email_with_activation(to, body, from, subject, attempts \\ 2) do
    mail_entity = send_email(to, body, from, subject)
    {:ok, mail_entity}
  rescue
    error ->
      Logger.error("Failed to send email with error: #{inspect(error)}")

      if attempts > 0 do
        Postmark.activate_email(to)
        send_email_with_activation(to, body, from, subject, attempts - 1)
      else
        {:error, {:internal_error, "Failed to send email"}}
      end
  end
end
