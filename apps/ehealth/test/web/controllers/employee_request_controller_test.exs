defmodule EHealth.Web.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Core.Expectations.Man
  import Mox

  alias Core.Contracts.CapitationContract
  alias Core.EmployeeRequests.EmployeeRequest, as: Request
  alias Core.Employees.Employee
  alias Core.EventManager.Event
  alias Core.EventManagerRepo
  alias Core.LegalEntities.LegalEntity
  alias Core.PartyUsers.PartyUser
  alias Core.PRMRepo
  alias Ecto.UUID

  @moduletag :with_client_id
  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  describe "create employee request" do
    setup %{conn: conn} do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_employee_type)
      insert(:il, :dictionary_speciality_type)

      {:ok, conn: conn}
    end

    test "with valid params and empty x-consumer-metadata", %{conn: conn} do
      conn = delete_client_id_header(conn)
      employee_request_params = File.read!("../core/test/data/employee_doctor_request.json")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      json_response(conn, 401)
    end

    test "with valid params and x-consumer-metadata that contains invalid client_id", %{
      conn: conn
    } do
      insert(:prm, :employee)
      employee_request_params = File.read!("../core/test/data/employee_doctor_request.json")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      json_response(conn, 422)
    end

    test "when user blacklisted", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :black_list_user, tax_id: "3067305998")
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 409)
      assert %{"error" => %{"message" => "new employee with this tax_id can't be created"}} = resp
    end

    test "with valid params and x-consumer-metadata that contains valid client_id", %{conn: conn} do
      msp()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      doctor = Map.delete(employee_request_params["employee_request"]["doctor"], "science_degree")
      employee_request_params = put_in(employee_request_params, ["employee_request", "doctor"], doctor)

      conn = put_client_id_header(conn, legal_entity.id)
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn1, 200)["data"]

      refute Map.has_key?(resp, "type")
      assert Map.has_key?(resp, "legal_entity_name")
      assert legal_entity.name == resp["legal_entity_name"]
      assert legal_entity.edrpou == resp["edrpou"]
      assert id == resp["employee_id"]
      request_party = employee_request_params["employee_request"]["party"]
      assert request_party["first_name"] == resp["first_name"]
      assert request_party["second_name"] == resp["second_name"]
      assert request_party["last_name"] == resp["last_name"]
      assert Map.has_key?(resp, "no_tax_id")
      refute resp["no_tax_id"]

      conn1 = get(conn, employee_request_path(conn, :show, resp["id"]))
      resp_by_id = json_response(conn1, 200)
      refute Map.has_key?(resp_by_id["data"]["doctor"], "science_degree")

      %{id: id} =
        insert(
          :prm,
          :employee,
          party: party,
          employee_type: Employee.type(:pharmacist)
        )

      legal_entity = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      employee_request_params =
        pharmacist_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "legal_entity_id"], legal_entity.id)

      conn2 = post(conn, employee_request_path(conn, :create), employee_request_params)
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

    test "without tax_id and employee_id with valid params and valid client_id", %{conn: conn} do
      msp()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      template()
      legal_entity = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "party", "tax_id"], "123456789")
        |> put_in(["employee_request", "party", "no_tax_id"], true)

      conn = put_client_id_header(conn, legal_entity.id)
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn1, 200)["data"]

      refute Map.has_key?(resp, "type")
      assert Map.has_key?(resp, "legal_entity_name")
      assert legal_entity.name == resp["legal_entity_name"]
      assert legal_entity.edrpou == resp["edrpou"]
      assert Map.has_key?(resp, "employee_id")
      refute resp["employee_id"]
      request_party = employee_request_params["employee_request"]["party"]
      assert request_party["no_tax_id"]

      conn = get(conn, employee_request_path(conn, :show, resp["id"]))
      resp_by_id = json_response(conn, 200)["data"]
      assert resp_by_id["party"]["no_tax_id"]
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

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :create), employee_request_params)
        |> json_response(422)

      assert Map.has_key?(resp, "error")
      assert resp["error"]
      assert 2 == Enum.count(get_in(resp, ["error", "invalid"]))

      employee_request_params =
        pharmacist_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "pharmacist"], %{})

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :create), employee_request_params)
        |> json_response(422)

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
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      invalid = hd(json_response(conn, 422)["error"]["invalid"])
      assert "$.employee_request.party.tax_id" == invalid["entry"]
    end

    test "without no_tax_id and x-consumer-metadata that contains valid client_id", %{conn: conn} do
      employee_request_params = doctor_request()

      party_without_no_tax_id =
        employee_request_params
        |> get_in(~W(employee_request party))
        |> Map.delete("no_tax_id")

      employee_request_params = put_in(employee_request_params, ~W(employee_request party), party_without_no_tax_id)

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      invalid = hd(json_response(conn, 422)["error"]["invalid"])
      assert "$.legal_entity_id" == invalid["entry"]
    end

    test "with doctor attribute for employee_type admin", %{conn: conn} do
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_type"], "ADMIN")
      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)

      json_response(conn, 422)
    end

    test "without doctor attribute for employee_type DOCTOR", %{conn: conn} do
      employee_request_params = doctor_request()

      employee_request_params =
        Map.put(
          employee_request_params,
          "employee_request",
          Map.delete(employee_request_params["employee_request"], "doctor")
        )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)

      json_response(conn, 422)
    end

    test "without pharmacist attribute for employee_type PHARMACIST", %{conn: conn} do
      employee_request_params = pharmacist_request()

      employee_request_params =
        Map.put(
          employee_request_params,
          "employee_request",
          Map.delete(employee_request_params["employee_request"], "pharmacist")
        )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)

      json_response(conn, 422)
    end

    test "with invalid params", %{conn: conn} do
      conn =
        post(conn, employee_request_path(conn, :create), %{
          "employee_request" => %{"invalid" => "data"}
        })

      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "with invalid birth_date", %{conn: conn} do
      employee_request_params =
        put_in(
          doctor_request(),
          ["employee_request", "party", "birth_date"],
          "1860-12-12"
        )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")

      assert "$.employee_request.party.birth_date" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")

      employee_request_params =
        put_in(
          employee_request_params,
          ["employee_request", "party", "birth_date"],
          "2003-02-29"
        )

      conn2 = post(conn, employee_request_path(conn, :create), employee_request_params)

      resp = json_response(conn2, 422)
      assert Map.has_key?(resp, "error")

      assert "$.employee_request.party.birth_date" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")
    end

    test "with invalid employee_type", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")

      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_type"], "INVALID")

      employee_request_params =
        Map.put(
          employee_request_params,
          "employee_request",
          Map.delete(employee_request_params["employee_request"], "doctor")
        )

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)

      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")

      assert "$.employee_request.employee_type" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")

      employee_request_params = put_in(employee_request_params, ["employee_request", "employee_type"], "DOCTORS")

      conn2 = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn2, 422)

      assert "$.employee_request.employee_type" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")
    end

    test "with OWNER employee_type", %{conn: conn} do
      employee_request_params = put_in(doctor_request(), ["employee_request", "employee_type"], Employee.type(:owner))

      employee_request_params =
        Map.put(
          employee_request_params,
          "employee_request",
          Map.delete(employee_request_params["employee_request"], "doctor")
        )

      conn = put_client_id_header(conn, "8b797c23-ba47-45f2-bc0f-521013e01074")
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)

      resp = json_response(conn1, 409)
      assert Map.has_key?(resp, "error")
      assert "Forbidden to create OWNER" == get_in(resp, ["error", "message"])

      employee_request_params =
        put_in(
          employee_request_params,
          ["employee_request", "employee_type"],
          Employee.type(:pharmacy_owner)
        )

      conn2 = post(conn, employee_request_path(conn, :create), employee_request_params)
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
        |> Jason.encode!()

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])

      invalid_division_id = Enum.find(resp["error"]["invalid"], fn x -> Map.get(x, "entry") == "$.division_id" end)
      assert nil != invalid_division_id
      assert Map.has_key?(invalid_division_id, "rules")
      assert 1 == length(invalid_division_id["rules"])
      rule = Enum.at(invalid_division_id["rules"], 0)
      assert "Division not found" == Map.get(rule, "description")
    end

    test "with invalid legal_entity_id", %{conn: conn} do
      employee_request_params =
        doctor_request()
        |> Jason.encode!()

      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert Map.has_key?(resp["error"], "invalid")
      assert 1 == length(resp["error"]["invalid"])
    end

    test "with invaid tax id", %{conn: conn} do
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "tax_id"], "1111111111")

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
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
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee = insert(:prm, :employee, division: division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], employee.id)
        |> put_in(["employee_request", "division_id"], division.id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      json_response(conn, 409)
    end

    test "with employee_id invalid employee_type", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      employee = insert(:prm, :employee, party: party, division: division, employee_type: "OWNER")

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], employee.id)
        |> put_in(["employee_request", "division_id"], division.id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      json_response(conn, 409)
    end

    test "with employee_id and valid tax_id, employee_type", %{conn: conn} do
      template()
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division, legal_entity: legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      employee = insert(:prm, :employee, party: party, division: division)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], employee.id)
        |> put_in(["employee_request", "division_id"], division.id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      json_response(conn, 200)
    end

    test "with invalid employee_id", %{conn: conn} do
      legal_entity_id = "8b797c23-ba47-45f2-bc0f-521013e01074"
      legal_entity = insert(:prm, :legal_entity, id: legal_entity_id)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], UUID.generate())
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 422)

      assert "$.employee_request.employee_id" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")
    end

    test "with not active employee", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "3067305998")

      %{id: id, division: %{id: division_id, legal_entity_id: legal_entity_id}} =
        :prm
        |> insert(:employee, status: "APPROVED", party: party, is_active: false)
        |> Core.PRMRepo.preload(:legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      assert json_response(conn, 404)
    end

    test "with dismissed employee", %{conn: conn} do
      party = insert(:prm, :party, tax_id: "3067305998")

      %{id: id, division: %{id: division_id, legal_entity_id: legal_entity_id}} =
        :prm
        |> insert(:employee, status: "DISMISSED", party: party)
        |> Core.PRMRepo.preload(:legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 409)
      assert "employee is dismissed" == get_in(resp, ["error", "message"])
    end

    test "with invalid party documents", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      doc = %{"type" => "PASSPORT", "number" => "120518"}
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "documents"], [doc, doc])
      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")

      assert "$.employee_request.party.documents[1].type" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")
    end

    test "with invalid party phones", %{conn: conn} do
      %{legal_entity_id: legal_entity_id} = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      ph = %{"type" => "MOBILE", "number" => "+380503410870"}
      employee_request_params = put_in(doctor_request(), ["employee_request", "party", "phones"], [ph, ph])
      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn1, 422)
      assert Map.has_key?(resp, "error")

      assert "$.employee_request.party.phones[1].type" ==
               resp
               |> get_in(["error", "invalid"])
               |> List.first()
               |> Map.get("entry")
    end

    test "with valid start_date", %{conn: conn} do
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "start_date"], "2017-08-07")

      conn
      |> put_client_id_header(legal_entity.id)
      |> post(employee_request_path(conn, :create), employee_request_params)
      |> json_response(200)
    end

    test "with invalid start_date - wrong format", %{conn: conn} do
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "start_date"], "2017-W08-7")

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 422)

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.employee_request.start_date",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "expected \"2017-W08-7\" to be an existing date",
                         "params" => [],
                         "rule" => "date"
                       }
                     ]
                   }
                 ]
               }
             } = resp
    end

    test "with invalid start_date - date is not exist", %{conn: conn} do
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "3067305998")
      %{id: id} = insert(:prm, :employee, party: party)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params =
        doctor_request()
        |> put_in(["employee_request", "employee_id"], id)
        |> put_in(["employee_request", "division_id"], division_id)
        |> put_in(["employee_request", "start_date"], "2017-02-29")

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :create), employee_request_params)
      resp = json_response(conn, 422)

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.employee_request.start_date",
                     "entry_type" => "json_data_property",
                     "rules" => [
                       %{
                         "description" => "expected \"2017-02-29\" to be an existing date",
                         "params" => [],
                         "rule" => "date"
                       }
                     ]
                   }
                 ]
               }
             } = resp
    end

    test "success doctor employee request", %{conn: conn} do
      msp()
      template()
      legal_entity = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      employee_request_params = put_in(doctor_request(), ["employee_request", "division_id"], division_id)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :create), employee_request_params)

      assert json_response(conn, 200)
    end

    test "doctor employee request failed when division_id attribute is absent", %{conn: conn} do
      msp()
      template()
      legal_entity = insert(:prm, :legal_entity)

      employee_request_params = doctor_request()
      attrs = Map.delete(employee_request_params["employee_request"], "division_id")
      employee_request_params = Map.put(employee_request_params, "employee_request", attrs)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :create), employee_request_params)

      resp = json_response(conn, 422)["error"]
      assert %{"message" => "Division does not exist"} = resp
    end

    test "non-doctor employee request is successful when division_id attribute is absent", %{conn: conn} do
      msp()
      template()
      legal_entity = insert(:prm, :legal_entity)

      employee_request_params = pharmacist_request()

      attrs =
        employee_request_params["employee_request"]
        |> Map.drop(~w(division_id pharmacist))
        |> Map.put("legal_entity_id", legal_entity.id)
        |> Map.put("employee_type", Employee.type(:admin))

      employee_request_params = Map.put(employee_request_params, "employee_request", attrs)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :create), employee_request_params)

      assert json_response(conn, 200)
    end
  end

  describe "create employee request with invalid specialities" do
    setup %{conn: conn} do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_employee_type)
      insert(:il, :dictionary_speciality_type)

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: insert(:prm, :party, tax_id: "3067305998"))
      %{id: division_id} = insert(:prm, :division)
      {:ok, conn: put_client_id_header(conn, legal_entity_id), division_id: division_id, employee_id: employee_id}
    end

    test "with invalid DOCTOR speciality", %{
      conn: conn,
      division_id: division_id,
      employee_id: employee_id
    } do
      request_params = doctor_request()

      speciality =
        request_params
        |> get_in(~w(employee_request doctor specialities))
        |> hd()
        |> Map.put("speciality", "PHARMACIST")

      employee_request_params =
        request_params
        |> put_in(~w(employee_request employee_id), employee_id)
        |> put_in(~w(employee_request division_id), division_id)
        |> put_in(~w(employee_request doctor specialities), [speciality])

      error =
        conn
        |> post(employee_request_path(conn, :create), employee_request_params)
        |> json_response(422)
        |> get_in(~w(error invalid))
        |> hd()

      assert "$.employee_request.doctor.specialities" = error["entry"]

      assert [
               %{
                 "description" => "speciality PHARMACIST with active speciality_officio is not allowed for doctor"
               }
             ] = error["rules"]
    end

    test "with invalid PHARMACIST speciality", %{
      conn: conn,
      division_id: division_id,
      employee_id: employee_id
    } do
      request_params = pharmacist_request()

      speciality =
        request_params
        |> get_in(~w(employee_request pharmacist specialities))
        |> hd()
        |> Map.put("speciality", "THERAPIST")

      employee_request_params =
        request_params
        |> put_in(~w(employee_request employee_id), employee_id)
        |> put_in(~w(employee_request division_id), division_id)
        |> put_in(~w(employee_request pharmacist specialities), [speciality])

      error =
        conn
        |> post(employee_request_path(conn, :create), employee_request_params)
        |> json_response(422)
        |> get_in(~w(error invalid))
        |> hd()

      assert "$.employee_request.pharmacist.specialities" = error["entry"]

      assert [
               %{
                 "description" => "speciality THERAPIST with active speciality_officio is not allowed for pharmacist"
               }
             ] = error["rules"]
    end

    test "more than one speciality with active speciality_officio", %{
      conn: conn,
      division_id: division_id,
      employee_id: employee_id
    } do
      request_params = pharmacist_request()

      speciality =
        request_params
        |> get_in(~w(employee_request pharmacist specialities))
        |> hd()

      employee_request_params =
        request_params
        |> put_in(~w(employee_request employee_id), employee_id)
        |> put_in(~w(employee_request division_id), division_id)
        |> put_in(~w(employee_request pharmacist specialities), [speciality, speciality])

      assert [
               %{
                 "description" => "employee have more than one speciality with active speciality_officio"
               }
             ] =
               conn
               |> post(employee_request_path(conn, :create), employee_request_params)
               |> json_response(422)
               |> get_in(~w(error invalid))
               |> hd()
               |> Map.get("rules")
    end

    test "no one speciality has active speciality_officio", %{
      conn: conn,
      division_id: division_id,
      employee_id: employee_id
    } do
      request_params = pharmacist_request()

      speciality =
        request_params
        |> get_in(~w(employee_request pharmacist specialities))
        |> hd()
        |> Map.put("speciality_officio", false)

      employee_request_params =
        request_params
        |> put_in(~w(employee_request employee_id), employee_id)
        |> put_in(~w(employee_request division_id), division_id)
        |> put_in(~w(employee_request pharmacist specialities), [speciality, speciality])

      assert [
               %{
                 "description" => "employee doesn't have speciality with active speciality_officio"
               }
             ] =
               conn
               |> post(employee_request_path(conn, :create), employee_request_params)
               |> json_response(422)
               |> get_in(~w(error invalid))
               |> hd()
               |> Map.get("rules")
    end
  end

  describe "list employee requests" do
    test "without filters", %{conn: conn} do
      msp()
      conn = get(conn, employee_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
    end

    test "by NHS ADMIN", %{conn: conn} do
      admin()
      legal_entity = insert(:prm, :legal_entity, id: "8b797c23-ba47-45f2-bc0f-521013e01074")
      insert(:il, :employee_request)
      insert(:il, :employee_request)
      conn = get(conn, employee_request_path(conn, :index))
      resp = json_response(conn, 200)["data"]
      assert 2 = length(resp)
      employee_request = hd(resp)
      assert legal_entity.edrpou == employee_request["edrpou"]
      assert legal_entity.name == employee_request["legal_entity_name"]
    end

    test "filter by no_tax_id", %{conn: conn} do
      admin()
      insert(:prm, :legal_entity, id: "8b797c23-ba47-45f2-bc0f-521013e01074")
      insert(:il, :employee_request)
      employee_data = put_in(employee_request_data(), ~w(party no_tax_id)a, true)
      insert(:il, :employee_request, data: employee_data)
      conn = get(conn, employee_request_path(conn, :index), no_tax_id: true)
      resp = json_response(conn, 200)["data"]
      assert 1 = length(resp)
      employee_request = hd(resp)
      assert Map.has_key?(employee_request, "no_tax_id")
      assert employee_request["no_tax_id"]
    end

    test "invalid no_tax_id", %{conn: conn} do
      admin(2)
      insert(:prm, :legal_entity, id: "8b797c23-ba47-45f2-bc0f-521013e01074")
      insert(:il, :employee_request)
      employee_data = put_in(employee_request_data(), ~w(party no_tax_id)a, true)
      insert(:il, :employee_request, data: employee_data)

      resp =
        conn
        |> get(employee_request_path(conn, :index), no_tax_id: "TrUe")
        |> json_response(200)
        |> Map.get("data")

      assert 1 = length(resp)
      employee_request = hd(resp)
      assert Map.has_key?(employee_request, "no_tax_id")
      assert employee_request["no_tax_id"]

      assert [] =
               conn
               |> get(employee_request_path(conn, :index), no_tax_id: "invalid")
               |> json_response(200)
               |> Map.get("data")
    end

    test "filter by legal_entity_name, edrpou and no_tax_id", %{conn: conn} do
      admin(3)
      # 1
      insert(:il, :employee_request)
      # 2
      %{id: legal_entity_id} = insert(:prm, :legal_entity, name: "АйБолит", edrpou: "10020030")
      employee_data = Map.put(employee_request_data(), :legal_entity_id, legal_entity_id)
      employee_request1 = insert(:il, :employee_request, data: employee_data)
      # 3
      %{id: legal_entity_id2} = insert(:prm, :legal_entity, name: "АйБолит 2", edrpou: "20030040")

      employee_data2 =
        employee_request_data()
        |> Map.put(:legal_entity_id, legal_entity_id2)
        |> put_in(~w(party no_tax_id)a, true)

      employee_request2 = insert(:il, :employee_request, data: employee_data2)

      # by legal_entity_name
      resp =
        conn
        |> get(employee_request_path(conn, :index), legal_entity_name: "боли")
        |> json_response(200)
        |> Map.get("data")

      assert 2 = length(resp)

      Enum.each(resp, fn %{"id" => id} ->
        assert id in [employee_request1.id, employee_request2.id]
      end)

      # legal_entity_name and edrpou
      resp =
        conn
        |> get(employee_request_path(conn, :index), legal_entity_name: "боли", edrpou: "10020030")
        |> json_response(200)
        |> Map.get("data")

      assert 1 = length(resp)
      assert employee_request1.id == hd(resp)["id"]

      # legal_entity_name and edrpou
      resp =
        conn
        |> get(employee_request_path(conn, :index), legal_entity_name: "боли", no_tax_id: "true")
        |> json_response(200)
        |> Map.get("data")

      assert 1 = length(resp)
      assert employee_request2.id == hd(resp)["id"]
    end

    test "filter by edrpou", %{conn: conn} do
      admin()
      insert(:il, :employee_request)
      %{id: legal_entity_id} = insert(:prm, :legal_entity, edrpou: "10020030")
      employee_data = Map.put(employee_request_data(), :legal_entity_id, legal_entity_id)
      %{id: id} = insert(:il, :employee_request, data: employee_data)

      resp =
        conn
        |> get(employee_request_path(conn, :index), edrpou: "10020030")
        |> json_response(200)
        |> Map.get("data")

      assert 1 = length(resp)
      assert id == hd(resp)["id"]
    end

    test "filter by employee_request_id", %{conn: conn} do
      admin()
      %{id: id} = insert(:il, :employee_request)
      insert(:il, :employee_request)

      resp =
        conn
        |> get(employee_request_path(conn, :index), id: id)
        |> json_response(200)
        |> Map.get("data")

      assert 1 = length(resp)
      assert id == hd(resp)["id"]
    end

    test "with valid client_id in metadata", %{conn: conn} do
      msp()
      %{id: legal_entity_id} = legal_entity = insert(:prm, :legal_entity)
      %{id: legal_entity_id_2} = insert(:prm, :legal_entity)

      data = employee_request_data() |> put_in([:legal_entity_id], legal_entity_id)
      data2 = employee_request_data() |> put_in([:legal_entity_id], legal_entity_id_2)

      insert(:il, :employee_request, data: data)
      insert(:il, :employee_request, data: data2)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, employee_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      edrpou = legal_entity.edrpou
      legal_entity_name = legal_entity.name

      assert [
               %{
                 "edrpou" => ^edrpou,
                 "legal_entity_name" => ^legal_entity_name,
                 "first_name" => "Петро",
                 "second_name" => "Миколайович",
                 "last_name" => "Іванов"
               }
             ] = resp["data"]
    end

    test "with invalid client_id in metadata", %{conn: conn} do
      msp()
      insert(:il, :employee_request)
      conn = get(conn, employee_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert Enum.empty?(resp["data"])
    end
  end

  test "get employee request with non-existing user", %{conn: conn} do
    msp()
    expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
    employee_request = %{id: id} = insert(:il, :employee_request)
    insert(:prm, :legal_entity, id: employee_request.data.legal_entity_id)

    conn = get(conn, employee_request_path(conn, :show, id))
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    data = resp["data"]
    assert Map.has_key?(data, "legal_entity_name")
    assert Map.has_key?(data, "no_tax_id")
    refute data["no_tax_id"]
    assert Map.get(employee_request, :id) == resp["data"]["id"]
    assert Map.get(employee_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(employee_request, :updated_at)) == resp["data"]["updated_at"]
    refute Map.has_key?(resp, "urgent")
  end

  test "get employee request with existing user", %{conn: conn} do
    msp()
    user_id = UUID.generate()

    expect(MithrilMock, :search_user, fn _, _ ->
      {:ok, %{"data" => [%{"id" => user_id}]}}
    end)

    fixture_params =
      employee_request_data()
      |> put_in([:party, :email], "test@user.com")

    insert(:prm, :legal_entity, id: fixture_params.legal_entity_id)

    fixture_request =
      %{id: id} =
      insert(
        :il,
        :employee_request,
        data: fixture_params
      )

    conn = get(conn, employee_request_path(conn, :show, id))
    resp = json_response(conn, 200)

    assert Map.has_key?(resp, "data")
    data = resp["data"]

    assert Map.has_key?(data, "legal_entity_name")
    assert Map.has_key?(data, "no_tax_id")
    refute data["no_tax_id"]
    assert Map.get(fixture_request, :id) == resp["data"]["id"]
    assert Map.get(fixture_request, :status) == resp["data"]["status"]
    assert NaiveDateTime.to_iso8601(Map.get(fixture_request, :inserted_at)) == resp["data"]["inserted_at"]
    assert NaiveDateTime.to_iso8601(Map.get(fixture_request, :updated_at)) == resp["data"]["updated_at"]
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], "user_id")
    assert user_id == resp["urgent"]["user_id"]
  end

  test "show employee_request with status NEW", %{conn: conn} do
    msp()
    expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
    employee_request = insert(:il, :employee_request)
    insert(:prm, :legal_entity, id: employee_request.data.legal_entity_id)
    conn = get(conn, employee_request_path(conn, :show, employee_request.id))
    resp = json_response(conn, 200)["data"]
    assert Map.has_key?(resp, "no_tax_id")
    refute resp["no_tax_id"]
  end

  test "create user by employee request", %{conn: conn} do
    msp()

    expect(MithrilMock, :create_user, fn _, _ ->
      {:ok, %{"data" => %{"email" => "test@user.com"}, "meta" => %{"code" => 201}}}
    end)

    fixture_params =
      employee_request_data()
      |> put_in([:party, :email], "test@user.com")

    %{id: id} = insert(:il, :employee_request, data: fixture_params)
    conn = post(conn, employee_request_path(conn, :create_user, id), %{"password" => "123"})
    resp = json_response(conn, 201)
    assert Map.has_key?(resp["data"], "email")
  end

  test "create user by employee request invalid params", %{conn: conn} do
    msp()
    fixture_params = employee_request_data() |> put_in([:party, :email], "test@user.com")
    %{id: id} = insert(:il, :employee_request, data: fixture_params)
    conn = post(conn, employee_request_path(conn, :create_user, id), %{"passwords" => "123"})
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "create user by employee request invalid id", %{conn: conn} do
    assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
      post(conn, employee_request_path(conn, :create_user, UUID.generate()), %{
        "password" => "pw"
      })
    end
  end

  describe "approve employee request" do
    setup %{conn: conn} do
      template(2)
      %{conn: conn}
    end

    test "can approve employee request with employee_id with changed party.name", %{conn: conn} do
      msp()
      get_user(2)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()
      user_id = UUID.generate()

      expect(MithrilMock, :get_user_roles, 3, fn user_id, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => user_id
             }
           ]
         }}
      end)

      get_roles_by_name(3, role_id)

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division)

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:division_id], division_id)
        |> put_in([:legal_entity_id], legal_entity_id)

      %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post(conn, employee_request_path(conn, :approve, request_id))
      resp = json_response(conn1, 200)
      assert %{"data" => %{"employee_id" => employee_id}} = resp

      {:ok, %{"data" => [role]}} = @mithril_api.get_user_roles(user_id, %{}, [])
      assert Map.has_key?(role, "role_id")

      data =
        data
        |> put_in([:party, :first_name], "Alex")
        |> put_in([:employee_id], employee_id)

      doctor = Map.delete(data.doctor, :science_degree)
      data = Map.put(data, :doctor, doctor)

      %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)
      conn2 = post(conn, employee_request_path(conn, :approve, request_id))
      resp = json_response(conn2, 200)["data"]
      assert employee_id = resp["employee_id"]
      refute Map.has_key?(resp["doctor"], "science_degree")
      conn3 = get(conn, employee_path(conn, :show, employee_id))
      resp = json_response(conn3, 200)["data"]
      refute Map.has_key?(resp["doctor"], "science_degree")
    end

    test "can approve employee request with employee_id and delete party.second_name", %{conn: conn} do
      msp()
      get_user(2)

      expect(ReportMock, :get_declaration_count, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      role_id = UUID.generate()

      expect(MithrilMock, :get_user_roles, 3, fn user_id, _, _ ->
        {:ok,
         %{
           "data" => [
             %{
               "role_id" => role_id,
               "user_id" => user_id
             }
           ]
         }}
      end)

      get_roles_by_name(3, role_id)

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: division_id} = insert(:prm, :division)

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :second_name], nil)
        |> put_in([:division_id], division_id)
        |> put_in([:legal_entity_id], legal_entity_id)

      party = insert(:prm, :party, tax_id: data.party.tax_id, birth_date: Date.from_iso8601!(data.party.birth_date))
      assert party.second_name
      %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

      conn = put_client_id_header(conn, legal_entity_id)
      conn1 = post(conn, employee_request_path(conn, :approve, request_id))
      resp = json_response(conn1, 200)
      assert %{"data" => %{"employee_id" => employee_id}} = resp
      party = PRMRepo.get(Core.Parties.Party, party.id)
      refute party.second_name
    end

    test "can approve pharmacist", %{conn: conn} do
      get_user()
      get_roles_by_name()
      get_user_roles()
      create_user_role()

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
      conn = post(conn, employee_request_path(conn, :approve, request_id))
      resp = json_response(conn, 200)["data"]
      assert %{"employee_id" => _employee_id, "pharmacist" => _} = resp
      assert %{additional_info: %{"educations" => _}} = PRMRepo.get(Employee, resp["employee_id"])
    end

    test "can approve employee request if email matches", %{conn: conn} do
      get_user()
      get_roles_by_name()
      get_user_roles()
      create_user_role()

      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483")

      %{legal_entity_id: legal_entity_id} =
        insert(
          :prm,
          :employee,
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
      conn = post(conn, employee_request_path(conn, :approve, request_id))
      assert [event] = EventManagerRepo.all(Event)

      assert %Event{
               entity_type: "EmployeeRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^request_id,
               properties: %{"status" => %{"new_value" => "APPROVED"}}
             } = event

      resp = json_response(conn, 200)["data"]
      assert "APPROVED" == resp["status"]
    end

    test "cannot approve employee request if email does not match", %{conn: conn} do
      get_user()
      %{id: id} = insert(:il, :employee_request)
      conn = post(conn, employee_request_path(conn, :approve, id))
      json_response(conn, 403)
    end

    test "cannot approve rejected employee request", %{conn: conn} do
      msp()
      get_user()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      test_invalid_status_transition(conn, "REJECTED", :approve)
    end

    test "cannot approve approved employee request", %{conn: conn} do
      msp()
      get_user()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      test_invalid_status_transition(conn, "APPROVED", :approve)
    end

    test "cannot approve employee request if you didn't create it'", %{conn: conn} do
      get_user()
      %{id: id} = insert(:il, :employee_request)
      conn = put_client_id_header(conn, UUID.generate())
      conn = post(conn, employee_request_path(conn, :approve, id))
      json_response(conn, 403)
    end

    test "can approve employee request if you created it'", %{conn: conn} do
      get_user()
      get_roles_by_name()
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483")

      employee =
        insert(
          :prm,
          :employee,
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

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = post(conn, employee_request_path(conn, :approve, employee_request.id))
      resp = json_response(conn, 200)["data"]
      assert "APPROVED" == resp["status"]
    end

    test "can approve employee request with employee_id'", %{conn: conn} do
      get_user()
      get_roles_by_name()
      get_user_roles()
      create_user_role()

      employee = insert(:prm, :employee)
      insert(:prm, :party, id: "01981ab9-904c-4c36-88ab-959a94087483", tax_id: "2222222225")
      %{id: division_id} = insert(:prm, :division)

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:division_id], division_id)
        |> put_in([:employee_id], employee.id)

      %{id: id, data: data} =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      legal_entity_id = data.legal_entity_id
      insert(:prm, :legal_entity, id: legal_entity_id)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = post(conn, employee_request_path(conn, :approve, id))
      resp = json_response(conn, 200)["data"]
      assert "APPROVED" == resp["status"]
    end

    test "cannot approve expired employee request", %{conn: conn} do
      get_user()

      %{id: id} =
        insert(
          :il,
          :employee_request,
          status: Request.status(:expired),
          data: %{"party" => %{"email" => "mis_bot_1493831618@user.com"}}
        )

      conn_resp = post(conn, employee_request_path(conn, :approve, id))
      resp = json_response(conn_resp, 403)
      assert "Employee request is expired" == resp["error"]["message"]
    end

    test "cannot approve employee request with existing user_id", %{conn: conn} do
      get_user()
      party = insert(:prm, :party, tax_id: "2222222225")
      %PartyUser{user_id: user_id} = insert(:prm, :party_user, party: party)

      request_data =
        employee_request_data()
        |> Map.delete("employee_id")
        |> put_in(~w(party email)a, "mis_bot_1493831618@user.com")

      %{id: id, data: data} = insert(:il, :employee_request, data: request_data)
      conn = put_client_id_header(conn, data.legal_entity_id)
      conn = Plug.Conn.put_req_header(conn, consumer_id_header(), user_id)
      conn_resp = post(conn, employee_request_path(conn, :approve, id))
      resp = json_response(conn_resp, 409)
      assert "Email is already used by another person" == resp["error"]["message"]
    end

    test "cannot approve employee request with existing user_id and party_id, but wrong party_user", %{conn: conn} do
      get_user()
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
      conn_resp = post(conn, employee_request_path(conn, :approve, id))
      resp = json_response(conn_resp, 409)
      assert "Email is already used by another person" == resp["error"]["message"]
    end
  end

  describe "update employee suspend contract" do
    test "approve new not-existing legal entity owner suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)

      birth_date = ~D[1991-08-19]
      tax_id = "3067305998"

      party =
        insert(
          :prm,
          :party,
          birth_date: birth_date,
          tax_id: tax_id
        )

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party,
          employee_type: "OWNER"
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      employee_request_data = employee_request_data()

      data =
        employee_request_data
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :birth_date], to_string(birth_date))
        |> put_in([:party, :tax_id], tax_id)
        |> put_in([:party, :first_name], "Димон")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)

      assert contract.is_suspended
    end

    test "approve existing employee as legal entity owner suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party,
          employee_type: "OWNER"
        )

      new_employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      employee_request_data = employee_request_data()

      data =
        employee_request_data
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :tax_id], "47542240")
        |> put_in([:party, :last_name], party.last_name)
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:employee_type], "OWNER")
        |> put_in([:employee_id], new_employee.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)

      assert false == contract.is_suspended
    end

    test "approve non-existing employee, suspend all party contracts", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()
      get_user()
      put_client()
      get_client_type_by_name(2)
      template(2)

      birth_date = ~D[1991-08-19]
      tax_id = "3067305998"

      party =
        insert(
          :prm,
          :party,
          birth_date: birth_date,
          tax_id: tax_id
        )

      division1 = insert(:prm, :division)
      division2 = insert(:prm, :division)
      legal_entity1 = insert(:prm, :legal_entity)
      legal_entity2 = insert(:prm, :legal_entity)

      employee1 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity1,
          division: division1,
          party: party,
          is_active: false,
          employee_type: "OWNER"
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee1)

      employee2 =
        build(
          :employee,
          legal_entity: legal_entity2,
          division: division2,
          party: party,
          employee_type: "OWNER"
        )

      # Create employee2

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :birth_date], to_string(birth_date))
        |> put_in([:party, :tax_id], tax_id)
        |> put_in([:party, :second_name], "Randomsky")
        |> put_in([:legal_entity_id], legal_entity2.id)
        |> put_in([:division_id], division2.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee2.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity2.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert contract.is_suspended
    end

    test "approve existing employee, suspend all party contracts", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()
      get_user()
      put_client()
      get_client_type_by_name(2)
      template(2)

      party = insert(:prm, :party)
      division1 = insert(:prm, :division)
      division2 = insert(:prm, :division)
      legal_entity1 = insert(:prm, :legal_entity)
      legal_entity2 = insert(:prm, :legal_entity)

      employee1 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity1,
          division: division1,
          party: party,
          employee_type: "OWNER"
        )

      employee2 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity2,
          division: division2,
          party: party,
          employee_type: "OWNER"
        )

      contract1 = insert(:prm, :capitation_contract, contractor_owner: employee1)
      contract2 = insert(:prm, :capitation_contract, contractor_owner: employee2)

      # Update employee1

      data =
        employee_request_data()
        |> put_in([:employee_id], employee1.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :second_name], "Vernadsky")
        |> put_in([:legal_entity_id], legal_entity1.id)
        |> put_in([:division_id], division1.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee1.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity1.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract1 = PRMRepo.get(CapitationContract, contract1.id)
      contract2 = PRMRepo.get(CapitationContract, contract2.id)
      assert contract1.is_suspended
      assert contract2.is_suspended
    end

    test "approve non-existing employee, keep party credentials", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()
      get_user()
      put_client()
      get_client_type_by_name(2)
      template(2)

      party = insert(:prm, :party)
      division1 = insert(:prm, :division)
      division2 = insert(:prm, :division)
      legal_entity1 = insert(:prm, :legal_entity)
      legal_entity2 = insert(:prm, :legal_entity)

      employee1 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity1,
          division: division1,
          party: party,
          is_active: false,
          employee_type: "OWNER"
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee1)

      employee2 =
        build(
          :employee,
          legal_entity: legal_entity2,
          division: division2,
          party: party
        )

      # Create employee2

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:legal_entity_id], legal_entity2.id)
        |> put_in([:division_id], division2.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee2.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity2.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert false == contract.is_suspended
    end

    test "approve existing employee, keep party credentials", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()
      get_user()
      put_client()
      get_client_type_by_name(2)
      template(2)

      party = insert(:prm, :party)
      division1 = insert(:prm, :division)
      division2 = insert(:prm, :division)
      legal_entity1 = insert(:prm, :legal_entity)
      legal_entity2 = insert(:prm, :legal_entity)

      employee1 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity1,
          division: division1,
          party: party,
          employee_type: "OWNER"
        )

      employee2 =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity2,
          division: division2,
          party: party,
          employee_type: "OWNER"
        )

      contract1 = insert(:prm, :capitation_contract, contractor_owner: employee1)
      contract2 = insert(:prm, :capitation_contract, contractor_owner: employee2)

      # Update employee1

      data =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:legal_entity_id], legal_entity1.id)
        |> put_in([:division_id], division1.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee1.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity1.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract1 = PRMRepo.get(CapitationContract, contract1.id)
      contract2 = PRMRepo.get(CapitationContract, contract2.id)
      assert false == contract1.is_suspended
      assert false == contract2.is_suspended
    end

    test "update employee first name suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      data =
        employee_request_data()
        |> put_in([:employee_id], employee.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :first_name], "Mario")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert contract.is_suspended == true
    end

    test "update employee last name suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      data =
        employee_request_data()
        |> put_in([:employee_id], employee.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :last_name], "Victorovich")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert contract.is_suspended == true
    end

    test "update employee second name suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)
      %{id: contract_id2} = insert(:prm, :capitation_contract)

      data =
        employee_request_data()
        |> put_in([:employee_id], employee.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:party, :second_name], "Vernadsky")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      contract2 = PRMRepo.get(CapitationContract, contract_id2)

      assert contract.is_suspended
      refute contract2.is_suspended
    end

    test "update employee type suspend contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      data =
        employee_request_data()
        |> put_in([:employee_id], employee.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:employee_type], "PHARMACIST")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert contract.is_suspended == true
    end

    test "update employee status contract", %{conn: conn} do
      create_user_role()
      get_user_roles()
      get_roles_by_name()

      get_user()
      put_client()

      get_client_type_by_name(2)
      template(2)

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      party = insert(:prm, :party)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division,
          party: party
        )

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)

      data =
        employee_request_data()
        |> put_in([:employee_id], employee.id)
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")
        |> put_in([:status], "OLD")
        |> put_in([:legal_entity_id], legal_entity.id)
        |> put_in([:division_id], division.id)
        |> put_in([:party_id], party.id)

      employee_request =
        insert(
          :il,
          :employee_request,
          employee_id: employee.id,
          data: data
        )

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> post(employee_request_path(conn, :approve, employee_request.id))
        |> json_response(200)
        |> Map.get("data")

      assert "APPROVED" == resp["status"]

      contract = PRMRepo.get(CapitationContract, contract.id)
      assert contract.is_suspended == true
    end
  end

  describe "reject employee request" do
    test "can reject employee request if email matches", %{conn: conn} do
      get_user()

      fixture_params =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")

      %{id: id} = insert(:il, :employee_request, data: fixture_params)
      insert(:prm, :legal_entity, id: fixture_params.legal_entity_id)

      conn = post(conn, employee_request_path(conn, :reject, id))
      resp = json_response(conn, 200)["data"]
      assert [event] = EventManagerRepo.all(Event)

      assert %Event{
               entity_type: "EmployeeRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^id,
               properties: %{"status" => %{"new_value" => "REJECTED"}}
             } = event

      assert "REJECTED" == resp["status"]
    end

    test "cannot reject employee request if email doesnot match", %{conn: conn} do
      get_user()
      %{id: id} = insert(:il, :employee_request, data: employee_request_data())

      conn = post(conn, employee_request_path(conn, :reject, id))
      json_response(conn, 403)
    end

    test "cannot reject rejected employee request", %{conn: conn} do
      msp()
      get_user()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)

      fixture_params =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")

      insert(:il, :employee_request, data: fixture_params)
      test_invalid_status_transition(conn, "REJECTED", :reject)
    end

    test "cannot reject approved employee request", %{conn: conn} do
      msp()
      get_user()
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      insert(:il, :employee_request, data: employee_request_data())
      test_invalid_status_transition(conn, "APPROVED", :reject)
    end

    test "cannot reject employee request if you didn't create it'", %{conn: conn} do
      msp()
      get_user()
      %{id: id} = insert(:il, :employee_request, data: employee_request_data())
      conn = post(conn, employee_request_path(conn, :reject, id))
      json_response(conn, 403)
    end

    test "can reject employee request if you created it'", %{conn: conn} do
      msp()
      get_user()

      fixture_params =
        employee_request_data()
        |> put_in([:party, :email], "mis_bot_1493831618@user.com")

      %{id: id, data: data} = insert(:il, :employee_request, data: fixture_params)

      legal_entity_id = data.legal_entity_id
      insert(:prm, :legal_entity, id: legal_entity_id)
      conn = post(conn, employee_request_path(conn, :reject, id))
      resp = json_response(conn, 200)["data"]
      assert "REJECTED" == resp["status"]
    end
  end

  describe "show invite" do
    test "success show invite", %{conn: conn} do
      expect(MithrilMock, :search_user, fn _, _ -> {:ok, %{"data" => []}} end)
      employee_request = insert(:il, :employee_request)
      insert(:prm, :legal_entity, id: employee_request.data.legal_entity_id)
      conn = get(conn, employee_request_path(conn, :invite, employee_request.id |> Cipher.encrypt() |> Base.encode64()))
      assert json_response(conn, 200)
    end

    test "fail show invite", %{conn: conn} do
      %{id: id} = insert(:il, :employee_request)
      conn = get(conn, employee_request_path(conn, :invite, id))
      assert json_response(conn, 404)
    end

    test "fail invalid id", %{conn: conn} do
      insert(:il, :employee_request)
      conn = get(conn, employee_request_path(conn, :invite, Base.encode64("invalid")))
      assert json_response(conn, 404)
    end
  end

  def test_invalid_status_transition(conn, init_status, action) do
    fixture_params =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")

    insert(:prm, :legal_entity, id: fixture_params.legal_entity_id)
    %{id: id} = insert(:il, :employee_request, data: fixture_params, status: init_status)

    conn_resp = post(conn, employee_request_path(conn, action, id))
    resp = json_response(conn_resp, 409)

    assert "Employee request status is #{init_status} and cannot be updated" == resp["error"]["message"]
    assert 409 = resp["meta"]["code"]
    conn = get(conn, employee_request_path(conn, :show, id))
    assert init_status == json_response(conn, 200)["data"]["status"]
  end

  defp doctor_request do
    "../core/test/data/employee_doctor_request.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp pharmacist_request do
    "../core/test/data/employee_pharmacist_request.json"
    |> File.read!()
    |> Jason.decode!()
  end
end
