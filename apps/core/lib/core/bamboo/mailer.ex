defmodule Core.Bamboo.PostmarkMailer do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :core
end

defmodule Core.Bamboo.MailgunMailer do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :core
end

defmodule Core.Bamboo.TestMailer do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :core
end

defmodule Core.Bamboo.SMTPMailer do
  @moduledoc false

  use Bamboo.Mailer, otp_app: :core
end
