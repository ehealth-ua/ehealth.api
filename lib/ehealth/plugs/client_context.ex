defmodule EHealth.Plugs.ClientContext do
  @moduledoc """
  Plug module that modifies query params for a requests with client context logic
  """
  use EHealth.Web, :plugs
  use Confex, otp_app: :ehealth

  alias EHealth.API.Mithril

  require Logger

  def put_is_active_into_params(%Plug.Conn{params: params} = conn, _) do
    %{conn | params: Map.merge(params, %{"is_active" => true})}
  end

  def process_client_context_for_list(%Plug.Conn{} = conn, _) do
    config = config()
    conn
    |> put_client_type_name()
    |> validate_params_list(config[:tokens_types_personal])
    |> put_context_params(config)
  end

  defp put_client_type_name(%Plug.Conn{req_headers: req_headers} = conn) do
    req_headers
    |> get_client_id()
    |> Mithril.get_client_details(req_headers)
    |> case do
        {:ok, %{"data" => %{"client_type_name" => client_type}}}
          -> assign(conn, :client_type, client_type)

        {:error, err}
          -> conn |> proxy(err) |> halt()
      end
  end

  defp validate_params_list(%Plug.Conn{halted: false, params: %{"legal_entity_id" => legal_entity_id}}
    = conn, personal_client_types) do

    # check that client_type is personal and requested entities is not allowed for this client
    if legal_entity_id_allowed?(conn, legal_entity_id, personal_client_types) do
      conn_empty_list(conn)
    else
      conn
    end
  end
  defp validate_params_list(conn, _config), do: conn

  defp legal_entity_id_allowed?(%Plug.Conn{} = conn, legal_entity_id, personal_client_types) do
    conn.assigns[:client_type] in personal_client_types and legal_entity_id != get_client_id(conn.req_headers)
  end

  defp put_context_params(%Plug.Conn{
    halted: false,
    params: params,
    assigns: %{client_type: client_type},
    req_headers: req_headers,
  } = conn, config) do

    client_id = get_client_id(req_headers)
    context_params =
      cond do
        client_type in config[:tokens_types_personal] -> %{"id" => client_id, "legal_entity_id" => client_id}
        client_type in config[:tokens_types_mis] -> %{}
        client_type in config[:tokens_types_admin] -> %{}
        true ->
          Logger.error(fn -> "Undefined client type name #{client_type} for /legal_entities. " <>
                "Cannot prepare params for request to PRM" end)
          %{"id" => client_id}
      end

    %{conn | params: Map.merge(params, context_params)}
  end
  defp put_context_params(conn, _config), do: conn

  defp conn_empty_list(conn) do
    conn
    |> assign_paging()
    |> render(EHealth.Web.LegalEntityView, "index.json", %{legal_entities: []})
    |> halt()
  end

  defp conn_forbidden(conn) do
    conn
    |> put_status(:forbidden)
    |> render(EView.Views.Error, :"403")
    |> halt()
  end

  defp assign_paging(conn) do
    paging = %{
      size: nil,
      limit: 50,
      has_more: false,
      cursors: %{
        starting_after: nil,
        ending_before: nil
      }
    }
    assign(conn, :paging, paging)
  end
end
