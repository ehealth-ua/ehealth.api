defmodule EHealth.Web.EUaddressesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "update settlement mountain group" do

    test "success", %{conn: conn} do
      division = insert(:prm, :division)
      data = %{"settlement" => %{"mountain_group" => true}}
      conn = patch conn, uaddresses_path(conn, :update_settlements, division.id), data

      assert json_response(conn, 200)["data"]["mountain_group"]
    end

    test "failed to update divisions", %{conn: conn} do
      division = insert(:prm, :division)
      data = %{"settlement" => %{"mountain_group" => "invalid"}}
      conn = patch conn, uaddresses_path(conn, :update_settlements, division.id), data

      assert 422 == json_response(conn, 422)["meta"]["code"]
    end

    test "settlement not set", %{conn: conn} do
      division = insert(:prm, :division)
      data = %{"mountain_group" => "invalid"}
      conn = patch conn, uaddresses_path(conn, :update_settlements, division.id), data
      assert 422 == json_response(conn, 422)["meta"]["code"]
    end

    test "no changes", %{conn: conn} do
      data = %{"settlement" => %{"name" => "Київ"}}
      conn = patch conn, uaddresses_path(conn, :update_settlements, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"), data

      assert [] != json_response(conn, 200)["meta"]["data"]

    end
  end
end
