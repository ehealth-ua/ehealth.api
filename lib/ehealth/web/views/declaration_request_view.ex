defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.DeclarationRequestView

  def render("show.json", %{declaration_request: declaration_request}) do
    render_one(declaration_request, DeclarationRequestView, "declaration_request.json")
  end

  def render("status.json", %{declaration_request: declaration_request}) do
    Map.take(declaration_request, [:id, :status])
  end

  def render("declaration_request.json", %{declaration_request: declaration_request}) do
    # TODO: move this to a module attr?
    legal_entity_attrs = [
      "id",
      "name",
      "short_name",
      "accreditation",
      "phones",
      "legal_form",
      "edrpou",
      "public_name",
      "licenses",
      "email",
      "addresses"
    ]

    employee = Map.take(declaration_request.data[:employee], ["id", "party", "position"])
    legal_entity = Map.take(declaration_request.data[:legal_entity], legal_entity_attrs)
    division = declaration_request.data[:division]

    data =
      declaration_request.data
      |> Map.put("id", declaration_request.id)
      |> Map.put("content", declaration_request.printout_content)
      |> Map.put("employee", employee)
      |> Map.put("legal_entity", legal_entity)
      |> Map.put("division", division)

    if declaration_request.documents do
      Map.put(data, "urgent", %{"documents" =>declaration_request.documents})
    else
      data
    end
  end

  def render("microservice_error.json", %{microservice_response: microservice_response}) do
    %{
      message: "Error during microservice interaction. Response from microservice: #{inspect microservice_response}."
    }
  end

  def render("unprocessable_entity.json", %{error: error}) do
    error
  end
end
