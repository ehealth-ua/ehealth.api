defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("show.json", %{declaration_request: declaration_request}) do
    declaration_request.data
  end

  def render("status.json", %{declaration_request: declaration_request}) do
    Map.take(declaration_request, [:id, :status])
  end

  def render("declaration_request.json", %{declaration_request: declaration_request}) do
    # TODO: move this to a module attr?

    division_attrs = [
      "id",
      "type",
      "phones",
      "name",
      "legal_entity_id",
      "external_id",
      "email",
      "addresses"
    ]

    employee = Map.take(declaration_request.data[:employee], ["id", "party", "position"])
    legal_entity = form_legal_entity(declaration_request.data[:legal_entity])
    division = Map.take(declaration_request.data[:division], division_attrs)

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

  defp form_legal_entity(legal_entity) do
    legal_entity_attrs = [
      "id",
      "name",
      "short_name",
      "phones",
      "legal_form",
      "edrpou",
      "public_name",
      "email",
      "addresses"
    ]

    msp_attrs = [
      "accreditation",
      "licenses"
    ]

    additional_attrs =
      legal_entity
      |> Map.get("medical_service_provider", msp_attrs)
      |> Map.take(msp_attrs)

    legal_entity
    |> Map.drop(["medical_service_provider"])
    |> Map.take(legal_entity_attrs)
    |> Map.merge(additional_attrs)
  end
end
