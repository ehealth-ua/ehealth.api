defmodule EHealth.Web.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import EHealth.SimpleFactory

  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee
  alias EHealth.PartyUsers.PartyUser
  alias EHealth.MockServer
  alias EHealth.PRMRepo

  @moduletag :with_client_id

  describe "create employee request" do
    setup (%{conn: conn}) do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_employee_type)

      {:ok, conn: conn}
    end

    test "with valid params and empty x-consumer-metadata", %{conn: conn} do
      conn = delete_client_id_header(conn)
      employee_request_params = File.read!("test/data/employee_doctor_request.json")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 401)
    end

    test "with valid params and x-consumer-metadata that contains invalid client_id", %{conn: conn} do
      insert(:prm, :employee)
      employee_request_params = File.read!("test/data/employee_doctor_request.json")
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 422)
    end

    test "when user blacklisted", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :black_list_user, tax_id: "3067305998")
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 409)
      assert %{"error" => %{"message" => "new employee with this tax_id can't be created"}} = resp
    end

    test "with valid params and x-consumer-metadata that contains valid client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn1, 200)["data"]
      refute Map.has_key?(resp, "type")
      assert Map.has_key?(resp, "legal_entity_name")
      assert legal_entity.name == resp["legal_entity_name"]
      assert legal_entity.edrpou == resp["edrpou"]
      request_party = employee_request_params["employee_request"]["party"]
      assert request_party["first_name"] == resp["first_name"]
      assert request_party["second_name"] == resp["second_name"]
      assert request_party["last_name"] == resp["last_name"]

      %{id: id} = insert(:prm, :employee,
        party: party,
        employee_type: Employee.type(:pharmacist)
      )

      legal_entity = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))
      conn = put_client_id_header(conn, legal_entity.id)
      employee_request_params =
        pharmacist_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "legal_entity_id"], legal_entity.id)

      conn2 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn2, 200)["data"]
      refute Map.has_key?(resp, "type")
      assert Map.has_key?(resp, "legal_entity_name")
      assert legal_entity.name == resp["legal_entity_name"]
      assert legal_entity.edrpou == resp["edrpou"]
      request_party = employee_request_params["employee_request"]["party"]
      assert request_party["first_name"] == resp["first_name"]
      assert request_party["second_name"] == resp["second_name"]
      assert request_party["last_name"] == resp["last_name"]
    end

    test "with invalid info params", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "doctor"], %{})

      conn = put_client_id_header(conn, legal_entity.id)
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
      assert 2 == Enum.count(get_in(resp, ["error", "invalid"]))

      employee_request_params =
        pharmacist_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "pharmacist"], %{})

      conn2 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn2, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
      assert 2 == Enum.count(get_in(resp, ["error", "invalid"]))
    end

    test "without tax_id and x-consumer-metadata that contains valid client_id", %{conn: conn} do
      employee_request_params = doctor_request()
      party_without_tax_id =
        employee_request_params
        |> get_in(~W(employee_request party))
        |> Map.delete("tax_id")

      employee_request_params = put_in(employee_request_params, ~W(employee_request party), party_without_tax_id)

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 422)
    end

    test "with doctor attribute for employee_type admin", %{conn: conn} do
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_type"], "ADMIN")
      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params

      json_response(conn, 422)
    end

    test "without doctor attribute for employee_type DOCTOR", %{conn: conn} do
      employee_request_params = doctor_request()
      employee_request_params = Map.put(employee_request_params, "employee_request",
        Map.delete(employee_request_params["employee_request"], "doctor"))

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params

      json_response(conn, 422)
    end

    test "without pharmacist attribute for employee_type PHARMACIST", %{conn: conn} do
      employee_request_params = pharmacist_request()
      employee_request_params = Map.put(employee_request_params, "employee_request",
        Map.delete(employee_request_params["employee_request"], "pharmacist"))

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post conn, employee_request_path(conn, :create), employee_request_params

      json_response(conn, 422)
    end

    test "with invalid params", %{conn: conn} do
      conn = post conn, employee_request_path(conn, :create), %{"employee_request" => %{"invalid" => "data"}}
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "with invalid birth_date", %{conn: conn} do
      employee_request_params = put_in(
        doctor_request(),
        ["employee_request", "party", "birth_date"],
        "1860-12-12"
      )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")
      assert "$.employee_request.party.birth_date" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")

      employee_request_params = put_in(
        employee_request_params,
        ["employee_request", "party", "birth_date"],
        "2003-02-29"
      )

      conn2 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn2, 422)
      assert Map.has_key?(resp, "error")
      assert "$.employee_request.party.birth_date" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")
    end

    test "with invalid employee_type", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
      )

      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_type"], "INVALID")

      employee_request_params = Map.put(
        employee_request_params,
        "employee_request",
        Map.delete(employee_request_params["employee_request"], "doctor")
      )

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")
      assert "$.employee_request.employee_type" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")

      employee_request_params = put_in(employee_request_params, ["employee_request", "employee_type"], "DOCTORS")

      conn2 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn2, 422)
      assert "$.employee_request.employee_type" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")
    end

    test "with OWNER employee_type", %{conn: conn} do
      employee_request_params =  put_in(doctor_request(), ["employee_request", "employee_type"], Employee.type(:owner))

      employee_request_params = Map.put(
        employee_request_params,
        "employee_request",
        Map.delete(employee_request_params["employee_request"], "doctor")
      )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn1, 409)
      assert Map.has_key?(resp, "error")
      assert "Forbidden to create OWNER" == get_in(resp, ["error", "message"])

      employee_request_params = put_in(
        employee_request_params,
        ["employee_request", "employee_type"],
        Employee.type(:pharmacy_owner)
      )

      conn2 = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn2, 409)
      assert Map.has_key?(resp, "error")
      assert "Forbidden to create PHARMACY_OWNER" == get_in(resp, ["error", "message"])
    end

    test "with non-existent foreign keys", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      employee = insert(:prm, :employee, party: party)
      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "division_id"], "356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> put_in(["employee_request", "employee_id"], employee.id)
        |> Poison.encode!()

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])

      invalid_division_id = Enum.find(resp["error"]["invalid"], fn(x) -> Map.get(x, "entry") == "$.division_id" end)
      assert nil != invalid_division_id
      assert Map.has_key?(invalid_division_id, "rules")
      assert 1 == length(invalid_division_id["rules"])
      rule = Enum.at(invalid_division_id["rules"], 0)
      assert "does not exist" == Map.get(rule, "description")
    end

    test "with invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      employee_request_params =
        doctor_request()
        |> Poison.encode!()
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])
    end

    test "with invaid tax id", %{conn: conn} do
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "tax_id"], "1111111111")

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])

      invalid_tax_id = Enum.at(resp["error"]["invalid"], 0)
      assert Map.has_key?(invalid_tax_id, "rules")
      assert 1 == length(invalid_tax_id["rules"])
      rule = Enum.at(invalid_tax_id["rules"], 0)
      assert "invalid tax_id value" == Map.get(rule, "description")
    end

    test "with employee_id invalid tax_id", %{conn: conn} do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee)
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_id"], employee.id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 409)
    end

    test "with employee_id invalid employee_type", %{conn: conn} do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party, tax_id: "3067305998")
      employee = insert(:prm, :employee, party: party, division: division, employee_type: "OWNER")

      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_id"], employee.id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 409)
    end

    test "with employee_id and valid tax_id, employee_type", %{conn: conn} do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party, tax_id: "3067305998")
      employee = insert(:prm, :employee, party: party, division: division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], employee.id)
        |> put_in(["employee_request", "division_id"], division.id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      json_response(conn, 200)
    end

    test "with invalid employee_id", %{conn: conn} do
      legal_entity_id = "8b797c23-ba47-45f2-bc0f-521013e01074"
      insert(:prm, :legal_entity, id: legal_entity_id)
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_id"], Ecto.UUID.generate())

      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 422)
      assert "$.employee_request.employee_id" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")
    end

    test "with not active employee", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id, division: %{legal_entity_id: legal_entity_id}} =
        :prm
        |> insert(:employee, status: "APPROVED", party: party, is_active: false)
        |> EHealth.PRMRepo.preload(:legal_entity)
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_id"], id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      assert json_response(conn, 404)
    end

    test "with dismissed employee", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id, division: %{legal_entity_id: legal_entity_id}} =
        :prm
        |> insert(:employee, status: "DISMISSED", party: party)
        |> EHealth.PRMRepo.preload(:legal_entity)
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_id"], id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post conn, employee_request_path(conn, :create), employee_request_params
      resp = json_response(conn, 409)
      assert "employee is dismissed" == get_in(resp, ["error", "message"])
    end

    test "with invalid party documents", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
      )

      doc = %{"type" => "PASSPORT", "number" => "120518"}
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "documents"], [doc, doc])

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")
      assert "$.employee_request.party.documents[1].type" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")
    end

    test "with invalid party phones", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
      )

      ph = %{"type" => "MOBILE", "number" => "+380503410870"}
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "phones"], [ph, ph])

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post conn, employee_request_path(conn, :create), employee_request_params

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")
      assert "$.employee_request.party.phones[1].type" ==
        resp
        |> get_in(["error", "invalid"])
        |> List.first()
        |> Map.get("entry")
      end
  end

  describe "list employee requests" do
    test "without filters", %{conn: conn} do
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
    end

    test "by NHS ADMIN", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "8b797c23-ba47-45f2-bc0f-521013e01074")
      insert(:il, :employee_request)
      insert(:il, :employee_request)
      conn = put_client_id_header(conn, MockServer.get_client_admin())
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)["data"]
      assert 2 = length(resp)
      employee_request = hd(resp)
      assert legal_entity.edrpou == employee_request["edrpou"]
      assert legal_entity.name == employee_request["legal_entity_name"]
    end

    test "with valid client_id in metadata", %{conn: conn} do
      %{id: legal_entity_id} = legal_entity = fixture(LegalEntity)
      %{id: legal_entity_id_2} = fixture(LegalEntity)
      fixture(Request, Map.put(employee_request(), :legal_entity_id, legal_entity_id))
      fixture(Request, Map.put(employee_request(), :legal_entity_id, legal_entity_id_2))

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      edrpou = legal_entity.edrpou
      legal_entity_name = legal_entity.name
      assert [%{
        "edrpou" => ^edrpou,
        "legal_entity_name" => ^legal_entity_name,
        "first_name" => "Петро",
        "second_name" => "Миколайович",
        "last_name" => "Іванов",
      }] = resp["data"]
    end

    test "with invalid client_id in metadata", %{conn: conn} do
      fixture(Request)
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      conn = get conn, employee_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 0 == length(resp["data"])
    end
  end

  test "get employee request with non-existing user", %{conn: conn} do
    employee_request = %{id: id} = fixture(Request)
    insert(:prm, :legal_entity, id: employee_request.data["legal_entity_id"])

    conn = get conn, employee_request_path(conn, :show, id)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")

    data = Map.drop(resp["data"], ["id", "inserted_at", "updated_at", "type", "status"])

    assert Map.get(employee_request, :data) ==
      Map.drop(data, ~w(
        employee_id
        edrpou
        legal_entity_name
        first_name
        last_name
        second_name
      ))
    assert Map.has_key?(data, "legal_entity_name")
    assert Map.get(employee_request, :id) == resp["data"]["id"]
    assert Map.get(employee_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :updated_at)) == resp["data"]["updated_at"]
    refute Map.has_key?(resp, "urgent")
  end

  test "get employee request with existing user", %{conn: conn} do
    fixture_params = employee_request() |> Map.put(:email, "test@user.com")
    fixture_request = %{id: id} = fixture(Request, fixture_params)

    conn = get conn, employee_request_path(conn, :show, id)
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")

    data = Map.drop(resp["data"], ["id", "inserted_at", "updated_at", "type", "status"])

    assert Map.get(fixture_request, :data) ==
      Map.drop(data, ~w(
        employee_id
        edrpou
        legal_entity_name
        first_name
        last_name
        second_name
      ))
    assert Map.has_key?(data, "legal_entity_name")
    assert Map.get(fixture_request, :id) == resp["data"]["id"]
    assert Map.get(fixture_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(fixture_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(fixture_request, :updated_at)) == resp["data"]["updated_at"]
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], "user_id")
    assert "userid" == resp["urgent"]["user_id"]
  end

  test "create user by employee request", %{conn: conn} do
    fixture_params = employee_request() |> Map.put(:email, "test@user.com")
    %{id: id} = fixture(Request, fixture_params)
    conn = post conn, employee_request_path(conn, :create_user, id), %{"password" => "123"}
    resp = json_response(conn, 201)
    assert Map.has_key?(resp["data"], "email")
  end

  test "create user by employee request invalid params", %{conn: conn} do
    fixture_params = employee_request() |> Map.put(:email, "test@user.com")
    %{id: id} = fixture(Request, fixture_params)
    conn = post conn, employee_request_path(conn, :create_user, id), %{"passwords" => "123"}
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "create user by employee request invalid id", %{conn: conn} do
    assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
      post conn, employee_request_path(conn, :create_user, Ecto.UUID.generate()), %{"password" => "pw"}
    end
  end

  test "can approve employee request with employee_id", %{conn: conn} do
    %{id: legal_entity_id} = insert(:prm, :legal_entity)
    %{id: division_id} = insert(:prm, :division)

    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:division_id], division_id)
      |> put_in([:legal_entity_id], legal_entity_id)
    %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

    conn = put_client_id_header(conn, legal_entity_id)
    conn1 = post conn, employee_request_path(conn, :approve, request_id)
    resp = json_response(conn1, 200)
    assert %{"data" => %{"employee_id" => employee_id}} = resp

    data =
      data
      |> put_in([:party, :first_name], "Alex")
      |> put_in([:employee_id], employee_id)
    %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)
    conn2 = post conn, employee_request_path(conn, :approve, request_id)
    resp = json_response(conn2, 200)
    assert %{"data" => %{"employee_id" => ^employee_id}} = resp
  end

  test "can approve pharmacist", %{conn: conn} do
    %{id: legal_entity_id} = insert(:prm, :legal_entity)
    %{id: division_id} = insert(:prm, :division)

    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:division_id], division_id)
      |> put_in([:legal_entity_id], legal_entity_id)
    data =
      data
      |> Map.put(:employee_type, Employee.type(:pharmacist))
      |> Map.put(:pharmacist, Map.get(data, :doctor))
      |> Map.delete(:doctor)
    %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

    conn = put_client_id_header(conn, legal_entity_id)
    conn = post conn, employee_request_path(conn, :approve, request_id)
    resp = json_response(conn, 200)["data"]
    assert %{"employee_id" => _employee_id, "pharmacist" => _} = resp
    assert %{additional_info: %{"educations" => _}} = PRMRepo.get(Employee, resp["employee_id"])
  end

  test "can approve employee request if email maches", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    party = insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483")
    %{legal_entity_id: legal_entity_id} = insert(:prm, :employee,
      legal_entity: legal_entity,
      party: party
    )
    %{id: division_id} = insert(:prm, :division)

    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:division_id], division_id)
      |> put_in([:legal_entity_id], legal_entity_id)
    %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

    conn = post conn, employee_request_path(conn, :approve, request_id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "cannot approve employee request if email doesnot match", %{conn: conn} do
    %{id: id} = fixture(Request)

    conn = post conn, employee_request_path(conn, :approve, id)
    json_response(conn, 403)
  end

  test "cannot approve rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :approve)
  end

  test "cannot approve approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :approve)
  end

  test "cannot approve employee request if you didn't create it'", %{conn: conn} do
    %{id: id} = fixture(Request)

    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = post conn, employee_request_path(conn, :approve, id)
    json_response(conn, 403)
  end

  test "can approve employee request if you created it'", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    division = insert(:prm, :division)
    party = insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483")
    employee = insert(:prm, :employee,
      legal_entity: legal_entity,
      division: division,
      party: party
    )
    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:legal_entity_id], legal_entity.id)
      |> put_in([:division_id], division.id)
      |> put_in([:party_id], party.id)
    employee_request = insert(:il, :employee_request,
      employee_id: employee.id,
      data: data
    )

    conn = put_client_id_header(conn, legal_entity.id)
    conn = post conn, employee_request_path(conn, :approve, employee_request.id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "can approve employee request with employee_id'", %{conn: conn} do
    employee = insert(:prm, :employee)
    insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483", tax_id: "2222222225")
    %{id: division_id} = insert(:prm, :division)
    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:division_id], division_id)
    %{id: id, data: data} = insert(:il, :employee_request,
      employee_id: employee.id,
      data: data
    )
    legal_entity_id = data.legal_entity_id
    insert(:prm, :legal_entity, id: legal_entity_id)

    conn = put_client_id_header(conn, legal_entity_id)
    conn = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn, 200)["data"]
    assert "APPROVED" == resp["status"]
  end

  test "cannot approve expired employee request", %{conn: conn} do
    %{id: id} = insert(:il, :employee_request,
      status: Request.status(:expired),
      data: %{"party" => %{"email" => "mis_bot_1493831618@user.com"}}
    )
    conn_resp = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn_resp, 403)
    assert "Employee request is expired" == resp["error"]["message"]
  end

  test "cannot approve employee request with existing user_id", %{conn: conn} do
    party = insert(:prm, :party, tax_id: "2222222225")
    %PartyUser{user_id: user_id} = insert(:prm, :party_user, party: party)
    request_data =
      employee_request_data()
      |> Map.delete("employee_id")
      |> put_in(~w(party email)a, "mis_bot_1493831618@user.com")
    %{id: id, data: data} = insert(:il, :employee_request, data: request_data)
    conn = put_client_id_header(conn, data.legal_entity_id)
    conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
    conn_resp = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn_resp, 409)
    assert "Email is already used by another person" == resp["error"]["message"]
  end

  test "cannot approve employee request with existing user_id and party_id, but wrong party_user", %{conn: conn} do
    tax_id = "2222222225"
    party = insert(:prm, :party, tax_id: tax_id)
    party2 = insert(:prm, :party, tax_id: "3222222225")
    %PartyUser{user_id: user_id} = insert(:prm, :party_user, party: party2)
    request_data =
      employee_request_data()
      |> Map.delete("employee_id")
      |> put_in(~w(party email)a, "mis_bot_1493831618@user.com")
      |> put_in(~w(party tax_id)a, tax_id)
      |> put_in(~w(party birth_date)a, party.birth_date)
    %{id: id, data: data} = insert(:il, :employee_request, data: request_data)
    conn = put_client_id_header(conn, data.legal_entity_id)
    conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
    conn_resp = post conn, employee_request_path(conn, :approve, id)
    resp = json_response(conn_resp, 409)
    assert "Email is already used by another person" == resp["error"]["message"]
  end

  test "can reject employee request if email matches", %{conn: conn} do
    fixture_params = employee_request() |> Map.put(:email, "mis_bot_1493831618@user.com")
    %{id: id} = fixture(Request, fixture_params)

    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  test "cannot reject employee request if email doesnot match", %{conn: conn} do
    %{id: id} = fixture(Request)

    conn = post conn, employee_request_path(conn, :reject, id)
    json_response(conn, 403)
  end

  test "cannot reject rejected employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "REJECTED", :reject)
  end

  test "cannot reject approved employee request", %{conn: conn} do
    test_invalid_status_transition(conn, "APPROVED", :reject)
  end

  test "cannot reject employee request if you didn't create it'", %{conn: conn} do
    %{id: id} = fixture(Request)

    conn = put_client_id_header(conn, Ecto.UUID.generate())
    conn = post conn, employee_request_path(conn, :reject, id)
    json_response(conn, 403)
  end

  test "can reject employee request if you created it'", %{conn: conn} do
    fixture_params = employee_request() |> Map.put(:email, "mis_bot_1493831618@user.com")
    %{id: id, data: data} = fixture(Request, fixture_params)

    conn = put_client_id_header(conn, Map.get(data, "legal_entity_id"))
    conn = post conn, employee_request_path(conn, :reject, id)
    resp = json_response(conn, 200)["data"]
    assert "REJECTED" == resp["status"]
  end

  def test_invalid_status_transition(conn, init_status, action) do
    fixture_params = employee_request() |> Map.merge(%{
      email: "mis_bot_1493831618@user.com",
      status: init_status
    })
    %{id: id} = fixture(Request, fixture_params)

    conn_resp = post conn, employee_request_path(conn, action, id)
    resp = json_response(conn_resp, 409)
    assert "Employee request status is #{init_status} and cannot be updated" == resp["error"]["message"]
    assert 409 = resp["meta"]["code"]

    conn = get conn, employee_request_path(conn, :show, id)
    assert init_status == json_response(conn, 200)["data"]["status"]
  end

  defp doctor_request do
    "test/data/employee_doctor_request.json"
    |> File.read!()
    |> Poison.decode!
  end

  defp pharmacist_request do
    "test/data/employee_pharmacist_request.json"
    |> File.read!()
    |> Poison.decode!
  end
end
