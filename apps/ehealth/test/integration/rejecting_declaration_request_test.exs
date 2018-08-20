defmodule EHealth.Integraiton.DeclarationRequestRejectTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias Ecto.UUID
  alias Core.DeclarationRequests.DeclarationRequest

  describe "rejecting declaration request" do
    test "succesfully reject declaration request" do
      client_id = UUID.generate()
      user_id = UUID.generate()

      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:new)
        )

      conn =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{record.id}/actions/reject")

      assert json_response(conn, 200)
    end

    test "inability to reject declaration request" do
      client_id = UUID.generate()
      user_id = UUID.generate()

      record =
        insert(
          :il,
          :declaration_request,
          status: DeclarationRequest.status(:signed)
        )

      conn =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{record.id}/actions/reject")

      assert json_response(conn, 409)
    end

    test "inability to reject non-existent request" do
      client_id = UUID.generate()
      user_id = UUID.generate()

      assert_raise Ecto.NoResultsError, fn ->
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: client_id}))
        |> patch("/api/declaration_requests/#{Ecto.UUID.generate()}/actions/reject")
      end
    end
  end
end
