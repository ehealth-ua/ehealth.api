defmodule EHealth.Man.Templates.HashChainVerificationNotification do
  @moduledoc false

  use Confex, otp_app: :ehealth

  @man_api Application.get_env(:core, :api_resolvers)[:man]

  def render(failure_details) do
    @man_api.render_template(
      config()[:id],
      %{
        format: config()[:format],
        locale: config()[:locale],
        failure_details: failure_details
      },
      []
    )
  end
end
