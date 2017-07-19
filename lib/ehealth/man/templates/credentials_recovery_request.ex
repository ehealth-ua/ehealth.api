defmodule EHealth.Man.Templates.CredentialsRecoveryRequest do
  @moduledoc false
  use Confex, otp_app: :ehealth
  alias EHealth.API.Man
  alias EHealth.Users.CredentialsRecoveryRequest

  def render(%CredentialsRecoveryRequest{id: id, user_id: user_id}) do
    template_data = %{
      credentials_recovery_request_id: id,
      user_id: user_id,
      format: config()[:format],
      locale: config()[:locale]
    }

    template_id = config()[:id]

    Man.render_template(template_id, template_data)
  end
end
