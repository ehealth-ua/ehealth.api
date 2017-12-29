defmodule EHealth.Web.PartyUserControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "list party users" do
    test "success list", %{conn: conn} do
      insert(:prm, :party_user)
      assert 1 =
               conn
               |> put_client_id_header()
               |> get(party_user_path(conn, :index))
               |> json_response(200)
               |> assert_list_response_schema("party_user")
               |> Map.get("data")
               |> length()
    end

    test "search by filters", %{conn: conn} do
      party = insert(:prm, :party, id: Ecto.UUID.generate(), tax_id: "123456")
      user_id = Ecto.UUID.generate()
      insert(:prm, :party_user, party: party, user_id: user_id)
      insert(:prm, :party_user)

      resp =
        conn
        |> put_client_id_header()
        |> get(party_user_path(conn, :index), %{"party_id" => party.id, "user_id" => user_id})
        |> json_response(200)
        |> assert_list_response_schema("party_user")
        |> Map.get("data")

      assert 1 == length(resp)
      assert user_id == hd(resp)["user_id"]
      assert party.id == hd(resp)["party_id"]
    end
  end
end
