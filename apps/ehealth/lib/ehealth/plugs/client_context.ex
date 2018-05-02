defmodule EHealth.Plugs.ClientContext do
  @moduledoc """
  Plug module that modifies query params for a requests with client context logic
  """
  use EHealth.Web, :plugs
  use Confex, otp_app: :ehealth

  alias EHealth.API.Mithril
  alias Scrivener.Page
  alias Plug.Conn

  require Logger

  @legal_entity_param_name_default "legal_entity_id"

  def put_is_active_into_params(%Conn{params: params} = conn, _) do
    %{conn | params: Map.merge(params, %{"is_active" => true})}
  end

  def process_client_context_for_list(%Conn{} = conn, plug_params) do
    config = config()

    conn
    |> put_client_type_name()
    |> check_client_type(plug_params)
    |> validate_params_list(config[:tokens_types_personal])
    |> put_context_params(plug_params)
  end

  defp check_client_type(%Conn{halted: false} = conn, required_types: required_types) when is_list(required_types) do
    if Enum.member?(required_types, Map.get(conn.assigns, :client_type)) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> render(EView.Views.Error, :"403")
      |> halt()
    end
  end

  defp check_client_type(conn, _), do: conn

  defp put_client_type_name(%Conn{req_headers: req_headers} = conn) do
    req_headers
    |> get_client_id()
    |> Mithril.get_client_type_name(req_headers)
    |> case do
      {:ok, nil} -> conn_unauthorized(conn)
      {:ok, client_type} -> assign(conn, :client_type, client_type)
      _ -> conn_unauthorized(conn)
    end
  end

  defp validate_params_list(
         %Plug.Conn{halted: false, params: %{"contractor_legal_entity_id" => legal_entity_id}} = conn,
         client_types
       ),
       do: do_validate_params_list(conn, legal_entity_id, client_types)

  defp validate_params_list(
         %Plug.Conn{halted: false, params: %{"legal_entity_id" => legal_entity_id}} = conn,
         client_types
       ),
       do: do_validate_params_list(conn, legal_entity_id, client_types)

  defp validate_params_list(conn, _personal_client_types), do: conn

  defp do_validate_params_list(conn, legal_entity_id, personal_client_types) do
    if legal_entity_id_not_allowed?(conn, legal_entity_id, personal_client_types) do
      conn_empty_list(conn)
    else
      conn
    end
  end

  defp legal_entity_id_not_allowed?(%Plug.Conn{} = conn, legal_entity_id, personal_client_types) do
    conn.assigns.client_type in personal_client_types and legal_entity_id != get_client_id(conn.req_headers)
  end

  defp put_context_params(
         %Conn{
           halted: false,
           params: params,
           assigns: %{client_type: client_type},
           req_headers: headers
         } = conn,
         plug_params
       ) do
    legal_entity_param_name = Keyword.get(plug_params, :legal_entity_param_name, @legal_entity_param_name_default)

    context_params =
      headers
      |> get_client_id()
      |> get_context_params(client_type, legal_entity_param_name)

    %{conn | params: Map.merge(params, context_params)}
  end

  defp put_context_params(conn, _plug_params), do: conn

  def get_context_params(client_id, client_type, legal_entity_param_name \\ @legal_entity_param_name_default) do
    config = config()

    cond do
      client_type in config[:tokens_types_personal] ->
        %{legal_entity_param_name => client_id}

      client_type in config[:tokens_types_mis] ->
        %{}

      client_type in config[:tokens_types_admin] ->
        %{}

      client_type in config[:tokens_types_cabinet] ->
        %{}

      true ->
        Logger.error(fn ->
          Poison.encode!(%{
            "log_type" => "error",
            "message" => "Undefined client type name #{client_type} for context request.",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        %{"legal_entity_id" => client_id}
    end
  end

  def authorize_legal_entity_id(legal_entity_id, client_id, client_type) do
    config = config()

    cond do
      client_type in config[:tokens_types_personal] and legal_entity_id != client_id ->
        {:error, :forbidden}

      client_type in config[:tokens_types_personal] ->
        :ok

      client_type in config[:tokens_types_mis] ->
        :ok

      client_type in config[:tokens_types_admin] ->
        :ok

      true ->
        Logger.error(fn ->
          Poison.encode!(%{
            "log_type" => "error",
            "message" => "Undefined client type name #{client_type} for context request.",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

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
      total_pages: 1
    }

    assign(conn, :paging, paging)
  end
end
