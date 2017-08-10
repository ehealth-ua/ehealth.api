defmodule EHealth.Web.LegalEntityController do
  @moduledoc """
  Sample controller for generated application.
  """
  use EHealth.Web, :controller

  alias EHealth.LegalEntity.API
  alias EHealth.PRM.LegalEntities
  alias EHealth.LegalEntity.LegalEntityUpdater

  action_fallback EHealth.Web.FallbackController

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, %{
      legal_entity: legal_entity,
      employee_request: employee_request,
      security: security}} <- API.create_legal_entity(legal_entity_params, req_headers) do

      conn
      |> assign_security(security)
      |> assign_employee_request_id(employee_request)
      |> render("show.json", legal_entity: Map.fetch!(legal_entity, "data"))
    end
  end

  def index(conn, params) do
    with {entities, paging} <- LegalEntities.get_legal_entities(params) do
      render(conn, "index.json", legal_entities: entities, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, legal_entity, security} <- API.get_legal_entity_by_id(id, req_headers) do
      conn
      |> assign_security(security)
      |> render("show.json", legal_entity: legal_entity)
    end
  end

  def mis_verify(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- API.mis_verify(id, req_headers) do
      proxy(conn, response)
    end
  end

  def nhs_verify(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- API.nhs_verify(id, req_headers) do
      proxy(conn, response)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{
      legal_entity_updated: %{"meta" => %{}} = response}} <- LegalEntityUpdater.deactivate(id, req_headers) do
      proxy(conn, response)
    end
  end

  defp assign_employee_request_id(conn, %EHealth.Employee.Request{id: id}) do
    assign_urgent(conn, "employee_request_id", id)
  end
  defp assign_employee_request_id(conn, _employee_request_id), do: conn
end
