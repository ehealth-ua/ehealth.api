defmodule EHealth.Man.Templates.EmailVerification do
  @moduledoc false
  use Confex, otp_app: :ehealth

  @man_api Application.get_env(:ehealth, :api_resolvers)[:man]

  def render(verification_code) do
    template_data = %{
      verification_code: verification_code,
      format: config()[:format],
      locale: config()[:locale]
    }

    template_id = config()[:id]

    @man_api.render_template(template_id, template_data)
  end
end
