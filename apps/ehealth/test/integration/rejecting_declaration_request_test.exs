defmodule EHealth.Integraiton.DeclarationRequestRejectTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "rejecting declaration request" do
    test "succesfully reject declaration request" do
      client_id = "8799e3b6-34e7-4798-ba70-d897235d2b6d"
      user_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      record = simple_fixture(:declaration_request, "NEW")

      conn =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{record.id}/actions/reject")

      assert json_response(conn, 200)
    end

    test "inability to reject declaration request" do
      client_id = "8799e3b6-34e7-4798-ba70-d897235d2b6d"
      user_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      record = simple_fixture(:declaration_request, "SIGNED")

      conn =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{record.id}/actions/reject")

      assert json_response(conn, 409)
    end

    test "inability to reject non-existent request" do
      client_id = "8799e3b6-34e7-4798-ba70-d897235d2b6d"
      user_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      assert_raise Ecto.NoResultsError, fn ->
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{Ecto.UUID.generate()}/actions/reject")
      end
    end
  end
end
