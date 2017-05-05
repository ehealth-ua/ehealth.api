defmodule EHealth.Web.LegalEntityController do
  @moduledoc """
  Sample controller for generated application.
  """
  use EHealth.Web, :controller

  alias EHealth.API.PRM
  alias EHealth.LegalEntity.API

  action_fallback EHealth.Web.FallbackController

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, legal_entity, security} <- API.create_legal_entity(legal_entity_params, req_headers) do
      conn
      |> assign_security(security)
      |> render("show.json", legal_entity: legal_entity)
    end
  end

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- PRM.get_legal_entities(params, req_headers) do
      proxy(conn, response)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- PRM.get_legal_entity_by_id(id, req_headers) do
      proxy(conn, response)
    end
  end

  defp assign_security(conn, security) when is_map(security) do
    assign(conn, :urgent, %{"security" => security})
  end
  defp assign_security(conn, _), do: conn
end
