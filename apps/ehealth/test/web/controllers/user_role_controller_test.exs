defmodule EHealth.Web.UserRoleControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  defmodule MicroserviceBaseTest do
    use EHealth.API.Helpers.MicroserviceBase
  end

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

  test "invalid request params" do
    error =
      {:error,
       [
         {%{
            description: "Request parameter client_id is not valid",
            params: [],
            rule: :invalid
          }, "$.client_id"}
       ]}

    options = [
      params: %{
        "client_id" => %{
          "0" => "7e9cffd9-c75f-45fb-badf-6e8d20b6a8a8",
          "1" => "7e9cffd9-c75f-45fb-badf-6e8d20b6a8a8"
        }
      }
    ]

    assert MicroserviceBaseTest.request(:get, "", "", [], options) == error

    options = [
      params: %{
        "client_id" => [
          "7e9cffd9-c75f-45fb-badf-6e8d20b6a8a8",
          "7e9cffd9-c75f-45fb-badf-6e8d20b6a8a8"
        ]
      }
    ]

    assert MicroserviceBaseTest.request(:get, "", "", [], options) == error
  end
end
