defmodule EHealth.Man.Templates.ContractRequestPrintoutForm do
  @moduledoc false

  use Confex, otp_app: :ehealth

  alias EHealth.ContractRequests.ContractRequest

  @man_api Application.get_env(:ehealth, :api_resolvers)[:man]

  def render(%ContractRequest{} = contract_request, headers) do
    template_data =
      contract_request
      |> Poison.encode!()
      |> Poison.decode!()
      |> Map.put(:format, config()[:format])
      |> Map.put(:locale, config()[:locale])

    template_id = config()[:id]
    @man_api.render_template(template_id, template_data, headers)
  end
end
