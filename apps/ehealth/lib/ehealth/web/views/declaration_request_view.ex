defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.DivisionView
  alias EHealth.Web.EmployeeView
  alias EHealth.Web.LegalEntityView
  alias EHealth.Web.PersonView

  def render("index.json", %{declaration_requests: declaration_requests}) do
    render_many(declaration_requests, __MODULE__, "declaration_request_short.json")
  end

  def render("declaration_request_short.json", %{declaration_request: %{data: data, id: id, status: status}}) do
    %{
      id: id,
      start_date: Map.get(data, "start_date"),
      end_date: Map.get(data, "end_date"),
      person: render(PersonView, "person_short.json", Map.take(data, ["person"])),
      employee: render(EmployeeView, "employee_short.json", Map.take(data, ["employee"])),
      legal_entity: render(LegalEntityView, "legal_entity_short.json", Map.take(data, ["legal_entity"])),
      division: render(DivisionView, "division_short.json", Map.take(data, ["division"])),
      status: status
    }
  end

  def render("declaration_request.json", %{declaration_request: declaration_request} = assigns) do
    response =
      declaration_request.data
      |> Map.put("id", declaration_request.id)
      |> Map.put("content", declaration_request.printout_content)
      |> Map.put("status", declaration_request.status)
      |> Map.put("declaration_id", declaration_request.declaration_id)
      |> Map.put("declaration_number", declaration_request.declaration_number)

    if Map.get(assigns, :hash) do
      Map.put(response, "seed", assigns.hash)
    else
      response
    end
  end

  def render("declaration.json", %{declaration: declaration}), do: declaration

  def render("otp.json", %{otp: otp}), do: otp

  def render("microservice_error.json", %{microservice_response: microservice_response}) do
    %{
      message: "Error during microservice interaction. Response from microservice: #{inspect(microservice_response)}."
    }
  end

  def render("unprocessable_entity.json", %{error: error}), do: error

  def render("declaration_request_short.json", %{declaration_request: declaration_request}) do
    Map.take(declaration_request, ~w(id status inserted_at)a)
  end

  def render("documents.json", %{documents: documents}) do
    render_many(documents, __MODULE__, "document.json")
  end

  def render("document.json", %{declaration_request: document}) do
    %{
      type: Map.get(document, "type"),
      url: Map.get(document, "url")
    }
  end
end
