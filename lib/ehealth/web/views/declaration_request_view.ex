defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.{PersonView, EmployeeView, LegalEntityView, DivisionView}
  alias EHealth.Utils.Phone

  def render("index.json", %{declaration_requests: declaration_requests}) do
    render_many(declaration_requests, __MODULE__, "declaration_request_short.json")
  end

  def render("declaration_request_short.json", %{"declaration_request": %{data: data}}) do
    %{
      id: Map.get(data, "id"),
      start_date: Map.get(data, "start_date"),
      end_date: Map.get(data, "end_date"),
      person: render(PersonView, "person_short.json", Map.take(data, ["person"])),
      employee: render(EmployeeView, "employee_short.json", Map.take(data, ["employee"])),
      legal_entity: render(LegalEntityView, "legal_entity_short.json", Map.take(data, ["legal_entity"])),
      division: render(DivisionView, "division_short.json", Map.take(data, ["division"])),
    }
  end

  def render("show.json", %{declaration_request: declaration_request}) do
    declaration_request.data
  end

  def render("status.json", %{declaration_request: declaration_request}) do
    Map.take(declaration_request, [:id, :data, :status])
  end

  def render("declaration_request.json", %{declaration_request: declaration_request, urgent: urgent}) do
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

    employee = Map.take(declaration_request.data["employee"], ["id", "party", "position"])
    legal_entity = form_legal_entity(declaration_request.data["legal_entity"])
    division = Map.take(declaration_request.data["division"], division_attrs)

    result =
      declaration_request.data
      |> Map.put("id", declaration_request.id)
      |> Map.put("content", declaration_request.printout_content)
      |> Map.put("employee", employee)
      |> Map.put("legal_entity", legal_entity)
      |> Map.put("division", division)
      |> Map.put("status", declaration_request.status)

    if urgent do
      filtered_authentication_method_current =
        update_in(declaration_request.authentication_method_current, ["number"], &Phone.hide_number/1)

      additional_fields =
        if declaration_request.documents do
          %{
            authentication_method_current: filtered_authentication_method_current,
            documents: filter_document_links(declaration_request.documents)
          }
        else
          %{
            authentication_method_current: filtered_authentication_method_current
          }
        end

      Map.put(result, "urgent", additional_fields)
    else
      result
    end
  end

  def render("declaration.json", %{declaration: declaration}), do: declaration

  def render("otp.json", %{otp: otp}), do: otp

  def render("microservice_error.json", %{microservice_response: microservice_response}) do
    %{
      message: "Error during microservice interaction. Response from microservice: #{inspect microservice_response}."
    }
  end

  def render("unprocessable_entity.json", %{error: error}), do: error

  def render("declaration_request_short.json", %{declaration_request: declaration_request}) do
    %{
      id: Map.get(declaration_request, :id),
      status: Map.get(declaration_request, :status),
      inserted_at: Map.get(declaration_request, :inserted_at)
    }
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

  defp filter_document_links(documents) do
    filter = fn document -> document["verb"] == "PUT" end
    map = fn document -> Map.drop(document, ["verb"]) end

    Enum.filter_map(documents, filter, map)
  end
end
