defmodule EHealth.Web.DivisionsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias Ecto.UUID

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "get divisions without x-client-id header", %{conn: conn} do
    conn = get conn, division_path(conn, :index)
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "get division by id without x-client-id header", %{conn: conn} do
    conn = get conn, division_path(conn, :show, UUID.generate())
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "create divisions without x-client-id header", %{conn: conn} do
    conn = post conn, division_path(conn, :create)
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "update divisions without x-client-id header", %{conn: conn} do
    conn = put conn, division_path(conn, :update, UUID.generate())
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "activate divisions without x-client-id header", %{conn: conn} do
    conn = patch conn, division_path(conn, :activate, UUID.generate())
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "deactivate divisions without x-client-id header", %{conn: conn} do
    conn = patch conn, division_path(conn, :deactivate, UUID.generate())
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "get divisions", %{conn: conn} do
    conn = put_client_id_header(conn)

    conn = get conn, division_path(conn, :index)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
  end

  test "get division by id", %{conn: conn} do
    conn = put_client_id_header(conn)

    id = "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
    conn = get conn, division_path(conn, :show, id)
    resp = json_response(conn, 200)["data"]

    assert id == resp["id"]
  end

  test "get division by id with wrong legal_entity_id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    conn = get conn, division_path(conn, :show, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "create division", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    conn = post conn, division_path(conn, :create), get_division()

    refute %{} == json_response(conn, 201)["data"]
  end

  test "update division", %{conn: conn} do
    conn = put_client_id_header(conn)
    conn = put conn, division_path(conn, :update, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"), get_division()

    assert 200 == json_response(conn, 200)["meta"]["code"]
  end

  test "update division with wrong legal_entity_id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    conn = put conn, division_path(conn, :update, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"), get_division()

    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "activate division", %{conn: conn} do
    conn = put_client_id_header(conn)
    conn = patch conn, division_path(conn, :activate, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

    assert 200 == json_response(conn, 200)["meta"]["code"]
  end

  test "deactivate division", %{conn: conn} do
    conn = put_client_id_header(conn)
    conn = patch conn, division_path(conn, :deactivate, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

    data = json_response(conn, 200)["data"]
    assert "INACTIVE" == data["status"]
    refute data["is_active"]
  end

  test "activate division with wrong legal_entity_id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch conn, division_path(conn, :activate, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "deactivate division with wrong legal_entity_id", %{conn: conn} do
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch conn, division_path(conn, :deactivate, "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  def get_division do
    "test/data/division.json"
    |> File.read!()
    |> Poison.decode!()
  end
end
