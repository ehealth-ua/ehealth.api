defmodule Core.Man.Templates.ReimbursementContractRequestPrintoutForm do
  @moduledoc false

  use Confex, otp_app: :core

  alias Core.ContractRequests.ReimbursementContractRequest

  @man_api Application.get_env(:core, :api_resolvers)[:man]

  def render(%ReimbursementContractRequest{}, headers) do
    template_id = config()[:id]

    @man_api.render_template(template_id, %{}, headers)
  end
end
