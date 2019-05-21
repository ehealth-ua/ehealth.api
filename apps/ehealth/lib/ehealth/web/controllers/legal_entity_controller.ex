defmodule EHealth.Web.LegalEntityController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.LegalEntities, as: API
  alias Core.LegalEntities.RelatedLegalEntities
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, %{legal_entity: legal_entity, employee_request: employee_request, security: security}} <-
           API.create(legal_entity_params, req_headers) do
      conn
      |> assign_security(security)
      |> assign_employee_request_id(employee_request)
      |> render("show.json", legal_entity: legal_entity)
    end
  end

  def index(conn, params) do
    # Respect MSP token
    legal_entity_id = Map.get(conn.params, "legal_entity_id")

    params =
      if is_nil(legal_entity_id),
        do: params,
        else: Map.put(params, "ids", legal_entity_id)

    with %Page{} = paging <- API.list(params) do
      render(conn, "index.json", legal_entities: paging.entries, paging: paging)
    end
  end

  def list_legators(%Plug.Conn{} = conn, params) do
    with %Page{} = paging <- RelatedLegalEntities.list(params, get_client_id(conn.req_headers)) do
      render(conn, "index.json", legal_entities: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, legal_entity} <- API.get_by_id(id, req_headers) do
      render(conn, "show.json", legal_entity: legal_entity)
    end
  end

  def nhs_verify(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, legal_entity} <- API.nhs_verify(%{id: id, nhs_verified: true}, get_consumer_id(req_headers)) do
      render(conn, "show.json", legal_entity: legal_entity)
    end
  end

  def assign_employee_request_id(conn, %Core.EmployeeRequests.EmployeeRequest{id: id}) do
    assign_urgent(conn, "employee_request_id", id)
  end

  def assign_employee_request_id(conn, _employee_request_id), do: conn
end
