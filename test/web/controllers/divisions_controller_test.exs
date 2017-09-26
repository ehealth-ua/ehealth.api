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

  describe "Get divisions" do
    test "get divisions", %{conn: conn} do
      conn = put_client_id_header(conn)

      conn = get conn, division_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
    end

    test "get INACTIVE divisions", %{conn: conn} do
      %{legal_entity_id: id} = insert(:prm, :division, status: "ACTIVE", is_active: true)
      conn = put_client_id_header(conn, id)

      conn1 = get conn, division_path(conn, :index, status: "INACTIVE")
      resp = json_response(conn1, 200)

      assert [] == resp["data"]

      conn2 = get conn, division_path(conn, :index, status: "ACTIVE")
      resp = json_response(conn2, 200)

      assert 1 == length(resp["data"])
    end
  end

  test "get division by id", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)

    conn = get conn, division_path(conn, :show, division.id)
    resp = json_response(conn, 200)["data"]

    assert division.id == resp["id"]
  end

  test "get divisions with  client_id that does not match legal entity id", %{conn: conn} do
    conn = put_client_id_header(conn, Ecto.UUID.generate())
    id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
    conn = get conn, division_path(conn, :index, [legal_entity_id: id])
    resp = json_response(conn, 200)
    assert [] == resp["data"]
    assert Map.has_key?(resp, "paging")
    assert String.contains?(resp["meta"]["url"], "/divisions")
  end

  test "get division by id with wrong legal_entity_id", %{conn: conn} do
    division = insert(:prm, :division)
    conn = put_client_id_header(conn, UUID.generate())
    conn = get conn, division_path(conn, :show, division.id)

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  test "create division with invalid address", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division_data = get_division()
    address =
      division_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.put("settlement", "Новосілки")

    division_data = Map.put(division_data, "addresses", [address])

    conn = put_client_id_header(conn, id)
    conn = post conn, division_path(conn, :create), division_data

    refute %{} == json_response(conn, 422)["error"]
  end

  test "create division with empty required address field", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division_data = get_division()
    address =
      division_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.delete("settlement")

    division_data = Map.put(division_data, "addresses", [address])

    conn = put_client_id_header(conn, id)
    conn = post conn, division_path(conn, :create), division_data
    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.addresses.[0].settlement" == err["entry"]
  end

  test "create division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = post conn, division_path(conn, :create), get_division()

    refute %{} == json_response(conn, 201)["data"]
  end

  test "create division without type and phone number", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = get_division() |> Map.delete("type") |> Map.put("phones", [%{"type": "MOBILE"}])
    conn = put_client_id_header(conn, id)
    conn = post conn, division_path(conn, :create), division

    assert [err1, err2] = json_response(conn, 422)["error"]["invalid"]
    assert "$.phones.[0].number" == err1["entry"]
    assert "$.type" == err2["entry"]
  end

  test "create division with invalid legal_entity", %{conn: conn} do
    division = get_division()
    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = post conn, division_path(conn, :create), division

    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.legal_entity_id" == err["entry"]
  end

  test "create division with invalid type", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = Map.put(get_division(), "type", "DRUGSTORE")
    conn = put_client_id_header(conn, id)
    conn = post conn, division_path(conn, :create), division

    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.type" == err["entry"]
    allowed_types =
      :ehealth
      |> Confex.fetch_env!(:legal_entity_division_types)
      |> Keyword.get(:msp)
    assert allowed_types == err["rules"] |> hd |> Map.get("params")
  end

  test "update division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = put conn, division_path(conn, :update, division.id), get_division()

    assert 200 == json_response(conn, 200)["meta"]["code"]
  end

  test "update division with wrong legal_entity_id", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = insert(:prm, :division)
    conn = put_client_id_header(conn, id)
    conn = put conn, division_path(conn, :update, division.id), get_division()

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  test "activate division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = patch conn, division_path(conn, :activate, division.id)

    assert 200 == json_response(conn, 200)["meta"]["code"]
  end

  test "deactivate division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = patch conn, division_path(conn, :deactivate, division.id)

    data = json_response(conn, 200)["data"]
    assert "INACTIVE" == data["status"]
    refute data["is_active"]
  end

  test "activate division with wrong legal_entity_id", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch conn, division_path(conn, :activate, division.id)

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  test "deactivate division with wrong legal_entity_id", %{conn: conn} do
    division = insert(:prm, :division)
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch conn, division_path(conn, :deactivate, division.id)

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  def get_division do
    "test/data/division.json"
    |> File.read!()
    |> Poison.decode!()
  end
end
