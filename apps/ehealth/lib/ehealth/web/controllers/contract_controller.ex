defmodule EHealth.Web.ContractController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Contracts

  action_fallback(EHealth.Web.FallbackController)

  def show(conn, %{"id" => id} = params) do
    with {:ok, {contract, references}} <- Contracts.get_by_id(id, params) do
      render(conn, "show.json", contract: contract, references: references)
    end
  end

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %{"data" => contracts, "paging" => paging}, references} <- Contracts.search(headers, client_type, params) do
      render(conn, "index.json", contracts: contracts, paging: paging, references: references)
    end
  end
end
