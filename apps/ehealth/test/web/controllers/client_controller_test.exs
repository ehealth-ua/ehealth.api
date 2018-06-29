defmodule EHealth.Web.ClientControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  describe "refresh client secret" do
    test "success refresh client secret", %{conn: conn} do
      id = UUID.generate()
      msp()

      expect(MithrilMock, :refresh_secret, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "type" => "client"
           },
           "meta" => %{"code" => 200}
         }}
      end)

      conn = put_client_id_header(conn, id)
      conn = patch(conn, client_path(conn, :refresh_secret, id))
      assert json_response(conn, 200)
    end

    test "failed to refresh client secret", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, client_path(conn, :refresh_secret, Ecto.UUID.generate()))
      assert json_response(conn, 403)
    end
  end
end
