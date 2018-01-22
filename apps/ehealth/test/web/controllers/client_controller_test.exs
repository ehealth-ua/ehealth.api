defmodule EHealth.Web.ClientControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  # import EHealth.MockServer, only: [get_client_admin: 0, get_client_mis: 0, get_client_nil: 0]

  describe "refresh client secret" do
    test "success refresh client secret", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = patch(conn, client_path(conn, :refresh_secret, "7cc91a5d-c02f-41e9-b571-1ea4f2375222"))
      assert json_response(conn, 200)
    end

    test "failed to refresh client secret", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = patch(conn, client_path(conn, :refresh_secret, Ecto.UUID.generate()))
      assert json_response(conn, 403)
    end
  end
end
