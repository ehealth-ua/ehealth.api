defmodule EHealth.Web.ClientController do
  @moduledoc false

  use EHealth.Web, :controller

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with params <- prepare_params(params),
         {:ok, %{"data" => clients, "paging" => paging}} <- @mithril_api.get_clients(params, headers) do
      paging =
        paging
        |> create_page()
        |> Map.put(:entries, clients)

      render(conn, "index.json", clients: clients, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with :ok <- validate_client_id(params),
         {:ok, %{"data" => client}} <- @mithril_api.get_client_details(id, headers) do
      render(conn, "show.json", client: client)
    end
  end

  defp prepare_params(%{"allowed_client_id" => client_id} = params), do: Map.put(params, "id", client_id)
  defp prepare_params(params), do: params

  defp validate_client_id(%{"allowed_client_id" => context_client_id, "id" => client_id}) do
    case context_client_id == client_id do
      true -> :ok
      false -> {:error, :forbidden}
    end
  end

  defp validate_client_id(_), do: :ok
end
