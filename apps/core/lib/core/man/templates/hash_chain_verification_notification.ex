defmodule Core.Man.Templates.HashChainVerificationNotification do
  @moduledoc false

  use Confex, otp_app: :core

  alias Core.Man.Client, as: ManClient

  def render(failure_details) do
    ManClient.render_template(
      config()[:id],
      %{
        format: config()[:format],
        locale: config()[:locale],
        failure_details: failure_details
      }
    )
  end
end
