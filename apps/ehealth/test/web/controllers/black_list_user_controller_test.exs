defmodule EHealth.Web.BlackListUserControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer

  describe "list black list users" do
    test "search by id", %{conn: conn} do
      %{id: id} = insert(:prm, :black_list_user)
      insert(:prm, :black_list_user)

      conn = get(conn, black_list_user_path(conn, :index), %{"id" => id})
      resp = json_response(conn, 200)["data"]

      assert 1 == length(resp)
      assert id == Map.get(hd(resp), "id")
      assert Map.get(hd(resp), "is_active")
    end

    test "search by invalid id", %{conn: conn} do
      conn = get(conn, black_list_user_path(conn, :index), %{"id" => "invalid"})
      assert json_response(conn, 422)
    end

    test "search by tax_id", %{conn: conn} do
      insert(:prm, :black_list_user)
      %{tax_id: tax_id} = insert(:prm, :black_list_user)

      conn = get(conn, black_list_user_path(conn, :index), %{"tax_id" => tax_id})
      resp = json_response(conn, 200)["data"]

      assert 1 == length(resp)
      assert tax_id == Map.get(hd(resp), "tax_id")
    end

    test "search by is_active", %{conn: conn} do
      %{id: id} = insert(:prm, :black_list_user, is_active: true)
      insert(:prm, :black_list_user, is_active: false)

      conn = get(conn, black_list_user_path(conn, :index), %{"is_active" => true})
      resp = json_response(conn, 200)["data"]

      assert 1 == length(resp)
      assert id == Map.get(hd(resp), "id")
      assert Map.get(hd(resp), "is_active")
    end

    test "search by all possible options", %{conn: conn} do
      %{id: id, tax_id: tax_id} = insert(:prm, :black_list_user, is_active: true)
      insert(:prm, :black_list_user, is_active: false)

      conn = get(conn, black_list_user_path(conn, :index), %{"is_active" => true, "tax_id" => tax_id})
      resp = json_response(conn, 200)
      data = resp["data"]

      assert 1 == length(data)
      assert id == Map.get(hd(data), "id")
      assert Map.get(hd(data), "is_active")
      assert tax_id == Map.get(hd(data), "tax_id")
    end
  end

  describe "create black list user" do
    test "success", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "0123456720")
      insert(:prm, :party_user, party: party, user_id: MockServer.get_user_for_role_1())
      insert(:prm, :party_user, party: party, user_id: MockServer.get_user_for_role_2())

      conn = post(conn, black_list_user_path(conn, :create), tax_id: "0123456720")
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, black_list_user_path(conn, :index), %{"id" => id})
      resp = json_response(conn, 200)["data"]

      assert 1 == length(resp)
      assert id == Map.get(hd(resp), "id")
      assert Map.get(hd(resp), "is_active")
    end

    test "users not blocked", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "1234567221")
      insert(:prm, :party_user, party: party)
      insert(:prm, :party_user, party: party)

      conn = post(conn, black_list_user_path(conn, :create), tax_id: "1234567221")
      resp = json_response(conn, 422)

      assert %{"error" => %{"invalid" => errors}} = resp

      Enum.each(errors, fn %{"entry" => entry} ->
        assert entry in ["$.users", "$.user_tokens"]
      end)
    end

    test "user already blacklisted", %{conn: conn} do
      %{tax_id: tax_id} = insert(:prm, :black_list_user)
      conn = post(conn, black_list_user_path(conn, :create), tax_id: tax_id)
      json_response(conn, 409)
    end

    test "invalid tax_id", %{conn: conn} do
      conn = post(conn, black_list_user_path(conn, :create), tax_id: "ME100900")
      resp = json_response(conn, 422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.tax_id"}]}} = resp
    end
  end

  describe "deactivate" do
    test "success", %{conn: conn} do
      %{id: id} = black_list_user = insert(:prm, :black_list_user)
      conn = patch(conn, black_list_user_path(conn, :deactivate, black_list_user))

      assert %{"id" => ^id, "is_active" => false} = json_response(conn, 200)["data"]
    end

    test "black list user is inactive", %{conn: conn} do
      black_list_user = insert(:prm, :black_list_user, is_active: false)

      conn = patch(conn, black_list_user_path(conn, :deactivate, black_list_user))
      json_response(conn, 409)
    end
  end
end
