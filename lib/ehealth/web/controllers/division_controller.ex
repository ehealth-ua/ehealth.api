defmodule EHealth.Web.DivisionController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Divisions.API

  action_fallback EHealth.Web.FallbackController

  @status_active "ACTIVE"
  @status_inactive "INACTIVE"

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.search(get_client_id(req_headers), params, req_headers) do
      proxy(conn, response)
    end
  end

  def create(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.create(get_client_id(req_headers), params, req_headers) do
      proxy(conn, response)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- API.get_by_id(get_client_id(req_headers), id, req_headers) do
      proxy(conn, response)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = division_params) do
    with {:ok, %{"meta" => %{}} = response} <- API.update(get_client_id(headers), id, division_params, headers) do
      proxy(conn, response)
    end
  end

  def activate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- API.update_status(get_client_id(headers), id, @status_active, headers) do
      proxy(conn, response)
    end
  end

  def deactivate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = resp} <- API.update_status(get_client_id(headers), id, @status_inactive, headers) do
      proxy(conn, resp)
    end
  end
end
