defmodule EHealth.Plugs.ClientContext do
  @moduledoc """
  Plug module that modifies query params for a requests with client context logic
  """
  use EHealth.Web, :plugs
  use Confex, otp_app: :ehealth

  alias EHealth.API.Mithril
  alias Scrivener.Page

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
    |> Mithril.get_client_type_name(req_headers)
    |> case do
         {:ok, nil} -> conn_unauthorized(conn)
         {:ok, client_type} -> assign(conn, :client_type, client_type)
         _ -> conn_unauthorized(conn)
       end
  end

  defp validate_params_list(%Plug.Conn{halted: false, params: %{"legal_entity_id" => legal_entity_id}}
    = conn, personal_client_types) do
    # check that client_type is personal and requested entities is allowed for this client
    if legal_entity_id_not_allowed?(conn, legal_entity_id, personal_client_types) do
      # consumer tries to filter list with not allowed legal_entity_id. Render empty list in this case
      conn_empty_list(conn)
    else
      conn
    end
  end
  defp validate_params_list(conn, _config), do: conn

  defp legal_entity_id_not_allowed?(%Plug.Conn{} = conn, legal_entity_id, personal_client_types) do
    conn.assigns.client_type in personal_client_types and legal_entity_id != get_client_id(conn.req_headers)
  end

  defp put_context_params(%Plug.Conn{
    halted: false,
    params: params,
    assigns: %{client_type: client_type},
    req_headers: req_headers,
  } = conn, config) do

    context_params = req_headers |> get_client_id() |> get_context_params(client_type, config)

    %{conn | params: Map.merge(params, context_params)}
  end
  defp put_context_params(conn, _config), do: conn

  def get_context_params(client_id, client_type, config \\ nil) do
    config = config || config()
    cond do
      client_type in config[:tokens_types_personal] -> %{"legal_entity_id" => client_id}
      client_type in config[:tokens_types_mis] -> %{}
      client_type in config[:tokens_types_admin] -> %{}
      true ->
        Logger.error("Undefined client type name #{client_type} for context request.")
        %{"legal_entity_id" => client_id}
    end
  end

  def authorize_legal_entity_id(legal_entity_id, client_id, client_type) do
    config = config()
    cond do
      client_type in config[:tokens_types_personal] and legal_entity_id != client_id -> {:error, :forbidden}
      client_type in config[:tokens_types_personal] -> :ok
      client_type in config[:tokens_types_mis] -> :ok
      client_type in config[:tokens_types_admin] -> :ok
      true ->
        Logger.error("Undefined client type name #{client_type} for context request.")
        {:error, :forbidden}
    end
  end

  defp conn_empty_list(conn) do
    conn
    |> assign_paging()
    |> render(EHealth.Web.LegalEntityView, "index.json", %{legal_entities: []})
    |> halt()
  end

  defp conn_unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401")
    |> halt()
  end

  defp assign_paging(conn) do
    paging = %Page{
      entries: [],
      page_number: 1,
      page_size: 50,
      total_entries: 0,
      total_pages: 1,
    }
    assign(conn, :paging, paging)
  end
end
