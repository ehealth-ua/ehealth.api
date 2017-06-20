defmodule EHealth.Man.Templates.DeclarationRequestPrintoutForm do
  @moduledoc false

  alias EHealth.API.Man

  use Confex, otp_app: :ehealth

  def render(declaration_request) do
    # TODO: decide what data is required to render the template

    template_data = %{
      declaration_request_id: declaration_request.id,
      format: config()[:format],
      locale: config()[:locale]
    }

    template_id = config()[:id]

    Man.render_template(template_id, template_data)
  end
end
