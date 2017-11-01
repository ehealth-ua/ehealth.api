defmodule EHealth.Web.PartyUserControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "list party users" do
    test "success list", %{conn: conn} do
      insert(:prm, :party_user)

      conn = put_client_id_header(conn)
      conn = get conn, party_user_path(conn, :index)
      resp = json_response(conn, 200)
      schema =
        "specs/json_schemas/party_user/party_user_list_response.json"
        |> File.read!
        |> Poison.decode!
      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert 1 == length(resp["data"])
    end

    test "search by filters", %{conn: conn} do
      party = insert(:prm, :party, id: Ecto.UUID.generate(), tax_id: "123456")
      user_id = Ecto.UUID.generate()
      insert(:prm, :party_user, party: party, user_id: user_id)
      insert(:prm, :party_user)

      conn = put_client_id_header(conn)
      conn = get conn, party_user_path(conn, :index), %{"party_id" => party.id, "user_id" => user_id}
      resp = json_response(conn, 200)
      schema =
        "specs/json_schemas/party_user/party_user_list_response.json"
        |> File.read!
        |> Poison.decode!
      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
      assert 1 == length(resp["data"])
      assert user_id == hd(resp["data"])["user_id"]
      assert party.id == hd(resp["data"])["party_id"]
    end
  end
end
