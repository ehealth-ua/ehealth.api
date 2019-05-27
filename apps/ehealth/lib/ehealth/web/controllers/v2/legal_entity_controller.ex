defmodule EHealth.Web.V2.LegalEntityController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.V2.LegalEntities, as: API
  alias EHealth.Web.LegalEntityController
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

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

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, legal_entity} <- API.get_by_id(id, req_headers) do
      render(conn, "show.json", legal_entity: legal_entity)
    end
  end

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, %{legal_entity: legal_entity, employee_request: employee_request, security: security}} <-
           API.create(legal_entity_params, req_headers) do
      conn
      |> assign_security(security)
      |> assign_employee_request_id(employee_request)
      |> render("show.json", legal_entity: legal_entity)
    end
  end

  defdelegate assign_employee_request_id(conn, employee_request_id), to: LegalEntityController
end
