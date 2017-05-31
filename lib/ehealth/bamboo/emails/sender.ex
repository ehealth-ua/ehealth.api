defmodule EHealth.Bamboo.Emails.Sender do
  @moduledoc false

  import Bamboo.Email
  alias EHealth.Bamboo.Mailer

  def send_email(to, body, from, subject) do
    new_email()
    |> to(to)
    |> from(from)
    |> subject(subject)
    |> html_body(body)
    |> Mailer.deliver_now()
  end
end
