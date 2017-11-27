defmodule EHealth.Web.DivisionController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Divisions, as: API
  alias EHealth.Divisions.Division

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with %Page{} = paging <- API.search(get_client_id(req_headers), params) do
      render(conn, "index.json", divisions: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, division} <- API.create(params, req_headers) do
      conn
      |> put_status(:created)
      |> render("show.json", division: division)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with %Division{} = division <- API.get_by_id!(id),
         :ok <- API.validate_legal_entity(division, get_client_id(req_headers))
    do
      render(conn, "show.json", division: division)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = division_params) do
    with {:ok, division} <- API.update(id, division_params, headers) do
      render(conn, "show.json", division: division)
    end
  end

  def activate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, division} <- API.update_status(id, Division.status(:active), headers) do
      render(conn, "show.json", division: division)
    end
  end

  def deactivate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, division} <- API.update_status(id, Division.status(:inactive), headers) do
      render(conn, "show.json", division: division)
    end
  end
end
