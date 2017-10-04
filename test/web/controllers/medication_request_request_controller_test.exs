defmodule EHealthWeb.MedicationRequestRequestControllerTest do
  use EHealth.Web.ConnCase, async: true

  alias EHealth.MedicationRequestRequests

  @legal_entity_id "7cc91a5d-c02f-41e9-b571-1ea4f2375552"

  def fixture(:medication_request_request) do
    {:ok, medication_request_request} = MedicationRequestRequests.create(test_request(),
                                                                         "7488a646-e31f-11e4-aace-600308960662",
                                                                         @legal_entity_id)
    medication_request_request
  end

  setup %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity, id: @legal_entity_id)
    division = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        legal_entity: legal_entity,
        is_active: true)
    insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )
    {:ok, conn: put_client_id_header(conn, legal_entity.id)}
  end

  describe "index" do
    test "lists all medication_request_requests", %{conn: conn} do
      conn = get conn, medication_request_request_path(conn, :index, %{"legal_entity_id" => @legal_entity_id})
      assert json_response(conn, 200)["data"] == []
    end
    test "lists all medication_request_requests with data", %{conn: conn} do
      mrr = fixture(:medication_request_request)
      conn = get conn, medication_request_request_path(conn, :index, %{"employee_id" => mrr.data.employee_id,
                                                                       "legal_entity_id" => @legal_entity_id})
      assert length(json_response(conn, 200)["data"]) == 1
    end
  end

  describe "create medication_request_request" do
    test "render medication_request_request when data is valid", %{conn: conn} do
      conn1 = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request()
      assert %{"id" => id} = json_response(conn1, 201)["data"]

      conn = get conn, medication_request_request_path(conn, :show, id)
      assert json_response(conn, 200)["data"]["data"] ==  %{
          "created_at" => "2020-09-22", "dispense_valid_from" => "2017-08-17",
          "dispense_valid_to" => "2017-09-16", "division_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          "employee_id" => "7488a646-e31f-11e4-aace-600308960662", "ended_at" => "2020-10-22",
          "legal_entity_id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552",
          "medication_id" => "1349a693-4db1-4a3f-9ac6-8c2f9e541982", "medication_qty" => 10,
          "person_id" => "585044f5-1272-4bca-8d41-8440eefe7d26", "started_at" => "2020-09-22"
        }
    end

    test "render errors when data is invalid", %{conn: conn} do
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: %{}
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "render errors when person_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("person_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.person_id"
    end

    test "render errors when employee_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("employee_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.employee_id"
    end

    test "render errors when division_id is invalid", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("division_id", "585041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      assert List.first(json_response(conn, 422)["error"]["invalid"])["entry"] == "$.data.division_id"
    end

    test "render errors when declaration doesn't exists", %{conn: conn} do
      test_request =
        test_request()
        |> Map.put("person_id", "575041f5-1272-4bca-8d41-8440eefe7d26")
      conn = post conn, medication_request_request_path(conn, :create), medication_request_request: test_request
      assert json_response(conn, 422)
      error_msg =
        conn
        |> json_response(422)
        |> get_in(["error", "invalid"])
        |> List.first
        |> Map.get("rules")
        |> List.first
        |> Map.get("description")
      assert error_msg == "Only doctors with an active declaration with the patient can create medication request!"
    end
  end

  defp test_request do
    "test/data/medication_request_request/medication_request_request.json"
    |> File.read!()
    |> Poison.decode!
  end
end
