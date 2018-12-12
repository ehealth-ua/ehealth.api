defmodule EHealth.Web.DivisionsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox

  alias Ecto.UUID

  setup %{conn: conn} do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_address_type)

    {:ok, conn: put_req_header(conn, "accept", "application/json"), address: build(:address)}
  end

  test "get divisions without x-client-id header", %{conn: conn} do
    conn = get(conn, division_path(conn, :index))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "get division by id without x-client-id header", %{conn: conn} do
    conn = get(conn, division_path(conn, :show, UUID.generate()))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "create divisions without x-client-id header", %{conn: conn} do
    conn = post(conn, division_path(conn, :create))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "update divisions without x-client-id header", %{conn: conn} do
    conn = put(conn, division_path(conn, :update, UUID.generate()))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "activate divisions without x-client-id header", %{conn: conn} do
    conn = patch(conn, division_path(conn, :activate, UUID.generate()))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  test "deactivate divisions without x-client-id header", %{conn: conn} do
    conn = patch(conn, division_path(conn, :deactivate, UUID.generate()))
    assert 401 == json_response(conn, 401)["meta"]["code"]
  end

  describe "Get divisions" do
    test "get divisions", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn)

      conn = get(conn, division_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
    end

    test "get divisions by valid ids", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)

      %{id: id1} = insert(:prm, :division, is_active: true, legal_entity: legal_entity)
      %{id: id2} = insert(:prm, :division, is_active: true, legal_entity: legal_entity)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(division_path(conn, :index, ids: "#{id1},#{id2}"))
        |> json_response(200)

      assert Map.has_key?(resp, "data")
      assert 2 == Enum.count(resp["data"])
    end

    test "get divisions by invalid ids", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)

      insert(:prm, :division, is_active: true, legal_entity: legal_entity)
      insert(:prm, :division, is_active: true, legal_entity: legal_entity)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(division_path(conn, :index, ids: "PROD,TEXT"))
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.ids",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "is invalid",
                     "params" => ["Elixir.Core.Ecto.CommaParamsUUID"],
                     "rule" => "cast"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "get divisions by valid and invalid ids", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)

      %{id: id1} = insert(:prm, :division, is_active: true, legal_entity: legal_entity)
      insert(:prm, :division, is_active: true, legal_entity: legal_entity)

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(division_path(conn, :index, ids: "#{id1},any_text"))
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.ids",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "is invalid",
                     "params" => ["Elixir.Core.Ecto.CommaParamsUUID"],
                     "rule" => "cast"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "get INACTIVE divisions", %{conn: conn} do
      msp(2)
      %{legal_entity_id: id} = insert(:prm, :division, status: "ACTIVE", is_active: true)
      conn = put_client_id_header(conn, id)

      conn1 = get(conn, division_path(conn, :index, status: "INACTIVE"))
      resp = json_response(conn1, 200)

      assert [] == resp["data"]

      conn2 = get(conn, division_path(conn, :index, status: "ACTIVE"))
      resp = json_response(conn2, 200)

      assert 1 == length(resp["data"])
    end

    test "divisions pagination", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      Enum.each(1..10, fn _ -> insert(:prm, :division, legal_entity: legal_entity) end)

      resp =
        conn
        |> get(division_path(conn, :index))
        |> json_response(200)

      assert 10 == length(resp["data"])
      assert 10 == resp["paging"]["total_entries"]
    end
  end

  test "get division by id", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)

    conn = get(conn, division_path(conn, :show, division.id))
    resp = json_response(conn, 200)["data"]

    assert division.id == resp["id"]
  end

  test "get divisions with client_id that does not match legal entity id", %{conn: conn} do
    msp()
    conn = put_client_id_header(conn, UUID.generate())
    id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
    conn = get(conn, division_path(conn, :index, legal_entity_id: id))
    resp = json_response(conn, 200)
    assert [] == resp["data"]
    assert Map.has_key?(resp, "paging")
    assert String.contains?(resp["meta"]["url"], "/divisions")
  end

  test "get division by id with wrong legal_entity_id", %{conn: conn} do
    division = insert(:prm, :division)
    conn = put_client_id_header(conn, UUID.generate())
    conn = get(conn, division_path(conn, :show, division.id))

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
    conn = post(conn, division_path(conn, :create), division_data)

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
    conn = post(conn, division_path(conn, :create), division_data)
    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.addresses.[0].settlement" == err["entry"]
  end

  test "create division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division_params = get_division()

    params =
      get_division()
      |> Map.get("addresses", [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))
      |> Map.put_new("region_id", UUID.generate())
      |> Map.put_new("district_id", nil)

    uaddresses_mock_expect(params)

    conn = put_client_id_header(conn, legal_entity.id)
    conn = post(conn, division_path(conn, :create), division_params)

    refute %{} == json_response(conn, 201)["data"]
  end

  test "create division without RESIDENCE address", %{conn: conn, address: address} do
    division = Map.put(get_division(), "addresses", [%{address | "type" => "REGISTRATION"}])

    legal_entity = insert(:prm, :legal_entity)

    resp =
      conn
      |> put_client_id_header(legal_entity.id)
      |> post(division_path(conn, :create), division)
      |> json_response(422)

    assert [%{"rules" => [%{"description" => decription}]}] = resp["error"]["invalid"]
    assert "Addresses with type RESIDENCE should be present" == decription
  end

  test "create division without type and phone number", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = get_division() |> Map.delete("type") |> Map.put("phones", [%{type: "MOBILE"}])
    conn = put_client_id_header(conn, id)
    conn = post(conn, division_path(conn, :create), division)

    assert [err1, err2] = json_response(conn, 422)["error"]["invalid"]
    assert "$.phones.[0].number" == err1["entry"]
    assert "$.type" == err2["entry"]
  end

  test "create division with invalid legal_entity", %{conn: conn} do
    division = get_division()
    conn = put_client_id_header(conn, UUID.generate())
    conn = post(conn, division_path(conn, :create), division)

    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.legal_entity_id" == err["entry"]
  end

  test "create division with invalid type", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = Map.put(get_division(), "type", "DRUGSTORE")
    conn = put_client_id_header(conn, id)
    conn = post(conn, division_path(conn, :create), division)

    assert [err] = json_response(conn, 422)["error"]["invalid"]
    assert "$.type" == err["entry"]

    allowed_types =
      :core
      |> Confex.fetch_env!(:legal_entity_division_types)
      |> Keyword.get(:msp)

    assert allowed_types == err["rules"] |> hd() |> Map.get("params")
  end

  test "create division with invalid working hours", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)

    params = Map.put(get_division(), "working_hours", [])
    conn1 = post(conn, division_path(conn, :create), params)
    assert json_response(conn1, 422)

    params = Map.put(get_division(), "working_hours", %{"invalid" => []})
    conn2 = post(conn, division_path(conn, :create), params)
    assert json_response(conn2, 422)

    params = Map.put(get_division(), "working_hours", %{"mon" => %{}})
    conn3 = post(conn, division_path(conn, :create), params)
    assert json_response(conn3, 422)

    params = Map.put(get_division(), "working_hours", %{"mon" => [["12", "25"]]})
    conn4 = post(conn, division_path(conn, :create), params)
    assert json_response(conn4, 422)
  end

  test "update division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)

    params =
      division
      |> Map.get(:addresses, [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))
      |> Map.put_new("region_id", UUID.generate())
      |> Map.put_new("district_id", nil)

    uaddresses_mock_expect(params)

    conn = put_client_id_header(conn, legal_entity.id)
    conn = put(conn, division_path(conn, :update, division.id), get_division())

    assert json_response(conn, 200)
  end

  test "update division with wrong legal_entity_id", %{conn: conn} do
    %{id: id} = insert(:prm, :legal_entity)
    division = insert(:prm, :division)

    params =
      division
      |> Map.get(:addresses, [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))
      |> Map.put_new("region_id", UUID.generate())
      |> Map.put_new("district_id", nil)

    uaddresses_mock_expect(params)

    conn = put_client_id_header(conn, id)
    conn = put(conn, division_path(conn, :update, division.id), get_division())

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  test "activate division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = patch(conn, division_path(conn, :activate, division.id))

    assert 200 == json_response(conn, 200)["meta"]["code"]
  end

  test "deactivate division", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, legal_entity.id)
    conn = patch(conn, division_path(conn, :deactivate, division.id))

    data = json_response(conn, 200)["data"]
    assert "INACTIVE" == data["status"]
    refute data["is_active"]
  end

  test "activate division with wrong legal_entity_id", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division, legal_entity: legal_entity)
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch(conn, division_path(conn, :activate, division.id))

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  test "deactivate division with wrong legal_entity_id", %{conn: conn} do
    division = insert(:prm, :division)
    conn = put_client_id_header(conn, UUID.generate())
    conn = patch(conn, division_path(conn, :deactivate, division.id))

    assert 403 == json_response(conn, 403)["meta"]["code"]
  end

  def get_division do
    "../core/test/data/division.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp uaddresses_mock_expect(params) do
    expect(UAddressesMock, :get_settlement_by_id, 3, fn _id, _headers ->
      get_settlement(
        %{
          "id" => params["settlement_id"],
          "region_id" => params["region_id"],
          "district_id" => params["district_id"]
        },
        200
      )
    end)

    expect_uaddresses_validate()
  end

  defp get_settlement(params, response_status, mountain_group \\ false) do
    settlement =
      %{
        "id" => UUID.generate(),
        "region_id" => UUID.generate(),
        "district_id" => UUID.generate(),
        "name" => "Сороки-Львівські",
        "mountain_group" => mountain_group
      }
      |> Map.merge(params)

    {:ok, %{"data" => settlement, "meta" => %{"code" => response_status}}}
  end
end
