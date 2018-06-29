defmodule EHealth.Web.UserRoleControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  test "get current user roles", %{conn: conn} do
    user_id = UUID.generate()
    client_id = UUID.generate()
    set_mox_global()

    expect(MithrilMock, :get_user_roles, fn _, _, _ ->
      {:ok, %{"data" => [%{"user_id" => user_id, "client_id" => client_id}]}}
    end)

    conn =
      conn
      |> put_req_header("x-consumer-id", user_id)
      |> put_client_id_header(client_id)

    conn = get(conn, user_role_path(conn, :index, client_id: client_id))
    assert [%{"user_id" => ^user_id, "client_id" => ^client_id}] = json_response(conn, 200)["data"]
  end
end
