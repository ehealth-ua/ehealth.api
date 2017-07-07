defmodule EHealth.Web.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.SimpleFactory

  test "get declaration request by invalid id", %{conn: conn} do
    conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
    assert_raise Ecto.NoResultsError, fn ->
      get conn, declaration_request_path(conn, :show, Ecto.UUID.generate())
    end
  end

  test "get declaration request by id", %{conn: conn} do
    conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
    %{id: id} = fixture(:declaration_request)
    conn = get conn, declaration_request_path(conn, :show, id)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
  end
end
