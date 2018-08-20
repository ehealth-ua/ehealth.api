defmodule Core.Bamboo.Emails.Sender do
  @moduledoc false

  use Confex, otp_app: :core
  import Bamboo.Email

  def send_email(to, body, from, subject) do
    new_email()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> html_body(body)
    |> config()[:mailer].deliver_now()
  end
end
