defmodule EHealth.Web.RegisterController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Scrivener.Page
  alias EHealth.Registers.API, as: Registers

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- Registers.list_registers(params) do
      render(conn, "index.json", registers: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, register} <- Registers.process_register_file(params, get_consumer_id(headers)) do
      conn
      |> put_status(:created)
      |> render("show.json", register: register)
    end
  end
end
