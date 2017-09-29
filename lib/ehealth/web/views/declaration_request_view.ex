defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.API.OPS
  alias EHealth.Web.{PersonView, EmployeeView, LegalEntityView, DivisionView}

  def render("index.json", %{declaration_requests: declaration_requests}) do
    render_many(declaration_requests, __MODULE__, "declaration_request_short.json")
  end

  def render("declaration_request_short.json", %{declaration_request: %{data: data, id: id}}) do
    %{
      id: id,
      start_date: Map.get(data, "start_date"),
      end_date: Map.get(data, "end_date"),
      person: render(PersonView, "person_short.json", Map.take(data, ["person"])),
      employee: render(EmployeeView, "employee_short.json", Map.take(data, ["employee"])),
      legal_entity: render(LegalEntityView, "legal_entity_short.json", Map.take(data, ["legal_entity"])),
      division: render(DivisionView, "division_short.json", Map.take(data, ["division"])),
    }
  end

  def render("declaration_request.json", %{declaration_request: declaration_request} = conn) do
    response =
      declaration_request.data
      |> Map.put("id", declaration_request.id)
      |> Map.put("content", declaration_request.printout_content)
      |> Map.put("status", declaration_request.status)

    if Map.get(conn, :display_hash) do
      {:ok, %{"data" => %{"hash" => hash}}} = OPS.get_latest_block()

      Map.put(response, "seed", hash)
    else
      response
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
