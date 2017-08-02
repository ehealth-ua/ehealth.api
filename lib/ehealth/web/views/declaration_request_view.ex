defmodule EHealth.Web.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view
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

  def render("declaration_request.json", %{declaration_request: declaration_request}) do
    declaration_request.data
    |> Map.put("id", declaration_request.id)
    |> Map.put("content", declaration_request.printout_content)
    |> Map.put("status", declaration_request.status)
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

  def render("images.json", %{images: images}) do
    render_many(images, __MODULE__, "image.json")
  end

  def render("image.json", %{declaration_request: image}) do
    %{
      type: Map.get(image, "type"),
      url: Map.get(image, "url")
    }
  end
end
