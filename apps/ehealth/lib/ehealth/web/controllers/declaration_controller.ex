defmodule EHealth.Web.DeclarationController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.Declarations.API

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{declarations: _, paging: _} = declarations_data} <- API.get_declarations(params, req_headers) do
      render(conn, "index.json", declarations_data)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, declaration} <- API.get_declaration_by_id(id, req_headers) do
      render(conn, "show.json", declaration: declaration)
    end
  end

  def reject(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    update_declaration(conn, id, %{"status" => "rejected", "updated_by" => get_consumer_id(headers)})
  end

  def approve(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    update_declaration(conn, id, %{"status" => "active", "updated_by" => get_consumer_id(headers)})
  end

  defp update_declaration(%Plug.Conn{req_headers: headers} = conn, id, patch) do
    with {:ok, declaration} <- API.update_declaration(id, patch, headers) do
      json(conn, declaration)
    end
  end

  def terminate(%Plug.Conn{req_headers: req_headers} = conn, attrs) do
    response = API.terminate_declarations(attrs, req_headers)
    wrap_response(conn, response)
  end

  def wrap_response(conn, response) do
    case response do
      {:ok, %{"meta" => %{"code" => 200}} = data} ->
        proxy(conn, data)

      {:error, %{"meta" => %{"code" => 422}, "error" => %{"message" => message}}} ->
        {:error, {:conflict, message}}

      _ ->
        response
    end
  end
end
