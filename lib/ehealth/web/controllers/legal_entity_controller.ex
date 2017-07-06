defmodule EHealth.Web.LegalEntityController do
  @moduledoc """
  Sample controller for generated application.
  """
  use EHealth.Web, :controller

  alias EHealth.API.PRM
  alias EHealth.LegalEntity.API

  action_fallback EHealth.Web.FallbackController

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, %{
      legal_entity_prm: legal_entity,
      security: security} = pipe_data} <- API.create_legal_entity(legal_entity_params, req_headers) do

      conn
      |> assign_security(security)
      |> assign_employee_request_id(Map.get(pipe_data, :employee_request))
      |> render("show.json", legal_entity: Map.fetch!(legal_entity, "data"))
    end
  end

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.get_legal_entities(params, req_headers) do
      proxy(conn, response)
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
    update_data = %{mis_verified: "VERIFIED"}

    with {:ok, %{"meta" => %{}} = response} <- PRM.update_legal_entity(update_data, id, req_headers) do
      proxy(conn, response)
    end
  end

  def nhs_verify(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    update_data = %{nhs_verified: true}

    with {:ok, %{"meta" => %{}} = response} <- PRM.update_legal_entity(update_data, id, req_headers) do
      proxy(conn, response)
    end
  end

  defp assign_employee_request_id(conn, %EHealth.Employee.Request{id: id}) do
    assign_urgent(conn, "employee_request_id", id)
  end
  defp assign_employee_request_id(conn, _employee_request_id), do: conn
end
