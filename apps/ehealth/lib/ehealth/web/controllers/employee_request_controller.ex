defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Core.EmployeeRequests, as: API
  alias Core.EmployeeRequests.EmployeeRequest, as: Request
  alias Scrivener.Page

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with {%Page{} = paging, references} <- API.list(params) do
      render(
        conn,
        "index.json",
        employee_requests: paging.entries,
        references: references,
        paging: paging
      )
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, employee_request} <- API.create(params, headers) do
      render(
        conn,
        "show.json",
        employee_request: employee_request,
        references: API.preload_references(employee_request)
      )
    end
  end

  def invite(conn, %{"id" => id} = params) do
    with {:ok, cipher_str} <- Base.decode64(id),
         id <- Cipher.decrypt(cipher_str),
         true <- is_binary(id) do
      show(conn, Map.put(params, "id", id))
    else
      :error -> nil
      false -> nil
      error -> error
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, employee_request, references} <- API.get_by_id(id) do
      conn
      |> put_urgent_user_id(employee_request)
      |> render(
        "show.json",
        employee_request: employee_request,
        references: references
      )
    end
  end

  def create_user(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.create_user_by_employee_request(params, req_headers) do
      proxy(conn, response)
    end
  end

  def approve(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with :ok <- API.check_employee_request(req_headers, id) do
      with {:ok, employee_request, references} <- API.approve(id, req_headers) do
        render(
          conn,
          "show.json",
          employee_request: employee_request,
          references: references
        )
      end
    end
  end

  def reject(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with :ok <- API.check_employee_request(req_headers, id) do
      with {:ok, employee_request, references} <- API.reject(id, req_headers) do
        render(
          conn,
          "show.json",
          employee_request: employee_request,
          references: references
        )
      end
    end
  end

  defp put_urgent_user_id(%Plug.Conn{req_headers: headers} = conn, %Request{data: data}) do
    email = get_in(data, ["party", "email"])

    %{email: email}
    |> @mithril_api.search_user(headers)
    |> process_user_id(conn)
  end

  defp process_user_id({:ok, body}, conn) do
    body
    |> Map.get("data")
    |> set_user_id(conn)
  end

  defp process_user_id({:error, _reason}, conn), do: conn

  defp set_user_id([%{"id" => user_id}], conn), do: assign(conn, :urgent, %{"user_id" => user_id})
  defp set_user_id(_, conn), do: conn
end
