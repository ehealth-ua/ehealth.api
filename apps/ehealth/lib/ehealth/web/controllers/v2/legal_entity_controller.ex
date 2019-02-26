defmodule EHealth.Web.V2.LegalEntityController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.V2.LegalEntities, as: API
  alias EHealth.Web.LegalEntityController

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

  defdelegate assign_employee_request_id(conn, employee_request_id), to: LegalEntityController
end
