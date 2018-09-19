defmodule EHealth.Web.ConnectionController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.Validators.JsonSchema

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with :ok <- validate_client_id(params),
         {:ok, %{"data" => connections, "paging" => paging}} <-
           @mithril_api.get_client_connections(params["client_id"], params, headers) do
      paging =
        paging
        |> create_page()
        |> Map.put(:entries, connections)

      render(conn, "index.json", connections: connections, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, params) do
    with :ok <- validate_client_id(params),
         {:ok, %{"data" => connection}} <-
           @mithril_api.get_client_connection(params["client_id"], params["id"], headers) do
      render(conn, "show.json", connection: connection)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, params) do
    with :ok <- validate_client_id(params),
         :ok <- JsonSchema.validate(:connection_update, Map.take(params, ~w(redirect_uri))),
         {:ok, %{"data" => connection}} <-
           @mithril_api.update_client_connection(params["client_id"], params["id"], params, headers) do
      render(conn, "show.json", connection: connection)
    end
  end

  def delete(%Plug.Conn{req_headers: headers} = conn, params) do
    with :ok <- validate_client_id(params),
         {:ok, _} <- @mithril_api.delete_client_connection(params["client_id"], params["id"], headers) do
      send_resp(conn, :no_content, "")
    end
  end

  def refresh_secret(%Plug.Conn{req_headers: headers} = conn, params) do
    with :ok <- validate_client_id(params),
         {:ok, %{"data" => connection}} <-
           @mithril_api.refresh_connection_secret(params["client_id"], params["id"], headers) do
      render(conn, "connection_with_secret.json", connection: connection)
    end
  end

  defp validate_client_id(%{"allowed_client_id" => context_client_id, "client_id" => client_id})
       when context_client_id != client_id do
    {:error, :forbidden}
  end

  defp validate_client_id(_), do: :ok
end
