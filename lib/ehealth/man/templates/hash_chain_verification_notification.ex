defmodule EHealth.Man.Templates.HashChainVerificationNotification do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.API.Man

  def render(failure_details) do
    Man.render_template(config()[:id], %{
      format: config()[:format],
      locale: config()[:locale],
      failure_details: failure_details
    })
  end
end
