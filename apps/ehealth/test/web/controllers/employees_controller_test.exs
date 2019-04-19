defmodule EHealth.Web.EmployeesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox

  alias Core.Employees.Employee
  alias Core.Parties.Party
  alias Ecto.UUID
  alias Core.PRMRepo
  alias Core.Contracts.CapitationContract

  setup :verify_on_exit!

  describe "list employees" do
    test "gets only employees that have legal_entity_id == client_id", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity, id: UUID.generate())
      %{id: legal_entity_id} = legal_entity
      party1 = insert(:prm, :party, tax_id: "2222222225")
      party2 = insert(:prm, :party, tax_id: "2222222224")
      insert(:prm, :employee, legal_entity: legal_entity, party: party1)

      insert(
        :prm,
        :employee,
        legal_entity: legal_entity,
        employee_type: Employee.type(:pharmacist),
        party: party2
      )

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, employee_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])

      first = Enum.at(resp["data"], 0)
      assert legal_entity_id == first["legal_entity"]["id"]

      second = Enum.at(resp["data"], 1)
      assert legal_entity_id == second["legal_entity"]["id"]
      assert Enum.any?(resp["data"], &Map.has_key?(&1, "doctor"))
      assert Enum.any?(resp["data"], &Map.has_key?(&1, "pharmacist"))
    end

    test "filter employees by invalid party_id", %{conn: conn} do
      msp()
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, employee_path(conn, :index, party_id: "invalid"))
      assert json_response(conn, 422)
    end

    test "get employees", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      %{id: legal_entity_id} = legal_entity
      party = insert(:prm, :party)
      insert(:prm, :employee, legal_entity: legal_entity, party: party)

      resp =
        conn
        |> put_client_id_header(legal_entity_id)
        |> get(employee_path(conn, :index))
        |> json_response(200)
        |> Map.get("data")
        |> assert_list_response_schema("employee")

      employee = List.first(resp)
      refute Map.has_key?(employee["doctor"], "science_degree")
      refute Map.has_key?(employee["doctor"], "qualifications")
      refute Map.has_key?(employee["doctor"], "educations")

      refute Map.has_key?(employee, "inserted_by")
      refute Map.has_key?(employee, "updated_by")
      refute Map.has_key?(employee, "is_active")
    end

    test "get employees by NHS ADMIN", %{conn: conn} do
      nhs()
      party1 = insert(:prm, :party, tax_id: "2222222225")
      party2 = insert(:prm, :party, tax_id: "2222222224")

      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, legal_entity: legal_entity, party: party1)
      insert(:prm, :employee, legal_entity: legal_entity, party: party2)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :index))
      resp = json_response(conn, 200)["data"]
      assert 2 = length(resp)
    end

    test "get employees with client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, employee_path(conn, :index, legal_entity_id: id))
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/employees")
    end

    test "search employees by tax_id" do
      msp()
      tax_id = "123"
      party = insert(:prm, :party, tax_id: tax_id)
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, party: insert(:prm, :party))
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      conn = put_client_id_header(build_conn(), legal_entity.id)
      conn = get(conn, employee_path(conn, :index, tax_id: tax_id))
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      party = PRMRepo.get(Party, resp |> hd() |> get_in(["party", "id"]))
      assert tax_id == party.tax_id
    end

    test "search employees by no_tax_id", %{conn: conn} do
      msp()
      party = insert(:prm, :party, no_tax_id: true)
      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      insert(:prm, :employee, party: insert(:prm, :party))
      %{id: id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)

      conn = get(conn, employee_path(conn, :index, no_tax_id: true))
      assert [data] = json_response(conn, 200)["data"]
      assert id == data["id"]
      assert data["party"]["no_tax_id"]
    end

    test "search employees by invalid tax_id" do
      msp()
      conn = put_client_id_header(build_conn())
      conn = get(conn, employee_path(conn, :index, tax_id: ""))
      resp = json_response(conn, 200)["data"]
      assert Enum.empty?(resp)
    end

    test "search employees by edrpou" do
      msp()
      edrpou = "37367387"
      legal_entity = insert(:prm, :legal_entity, edrpou: edrpou)
      insert(:prm, :employee, legal_entity: legal_entity)
      insert(:prm, :employee)
      conn = put_client_id_header(build_conn(), legal_entity.id)
      conn = get(conn, employee_path(conn, :index, edrpou: edrpou))
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
    end

    test "search employees by invalid edrpou" do
      msp()
      conn = put_client_id_header(build_conn())
      conn = get(conn, employee_path(conn, :index, edrpou: ""))
      resp = json_response(conn, 200)["data"]
      assert Enum.empty?(resp)
    end
  end

  describe "get employee by id" do
    test "with party, division, legal_entity", %{conn: conn} do
      msp(2)
      legal_entity = insert(:prm, :legal_entity)

      speciality_officio = %{
        "speciality" => "PEDIATRICIAN",
        "level" => "Перша категорія",
        "qualification_type" => "Присвоєння",
        "attestation_name" => "Академія Богомольця",
        "attestation_date" => "2017-08-04",
        "valid_to_date" => "2017-08-05",
        "certificate_number" => "AB/21331",
        "speciality_officio" => true
      }

      specialities = [
        speciality_officio,
        %{
          "speciality" => "PHARMACIST",
          "level" => "Перша категорія",
          "qualification_type" => "Присвоєння",
          "attestation_name" => "Академія Богомольця",
          "attestation_date" => "2017-08-04",
          "valid_to_date" => "2017-08-05",
          "certificate_number" => "AB/21331",
          "speciality_officio" => false
        }
      ]

      party1 =
        insert(
          :prm,
          :party,
          tax_id: "2222222225",
          specialities: specialities
        )

      employee = insert(:prm, :employee, legal_entity: legal_entity, party: party1, speciality: speciality_officio)
      conn = put_client_id_header(conn, legal_entity.id)

      data =
        conn
        |> get(employee_path(conn, :show, employee.id))
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(data, "employee")
      assert specialities == data["doctor"]["specialities"]

      party2 = insert(:prm, :party, tax_id: "2222222224")

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          employee_type: Employee.type(:pharmacist),
          party: party2
        )

      conn
      |> get(employee_path(conn, :show, employee.id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("employee")
    end

    test "without division", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity, division: nil)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :show, employee.id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp["data"], "party")
      assert Map.has_key?(resp["data"], "legal_entity")

      refute Map.has_key?(resp["data"]["party"], "data")
      refute Map.has_key?(resp["data"]["party"], "updated_by")
      refute Map.has_key?(resp["data"]["party"], "created_by")

      refute Map.has_key?(resp["data"]["legal_entity"], "data")
      refute Map.has_key?(resp["data"]["legal_entity"], "updated_by")
      refute Map.has_key?(resp["data"]["legal_entity"], "created_by")

      refute Map.has_key?(resp["data"], "division_id")
      refute resp["data"]["division"]
    end

    test "with MSP token when legal_entity_id != client_id", %{conn: conn} do
      msp()
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 403)
    end

    test "with MIS token when legal_entity_id != client_id", %{conn: conn} do
      mis()
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 200)
    end

    test "with ADMIN token when legal_entity_id != client_id", %{conn: conn} do
      admin()
      employee = insert(:prm, :employee)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, employee_path(conn, :show, employee.id))
      json_response(conn, 200)
    end

    test "when legal_entity_id == client_id", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, employee_path(conn, :show, employee.id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_map(resp["data"])
    end

    test "employee is not active", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      employee = insert(:prm, :employee, legal_entity: legal_entity, is_active: false)

      assert_raise(Ecto.NoResultsError, fn ->
        conn
        |> put_client_id_header(legal_entity.id)
        |> get(employee_path(conn, :show, employee.id))
        |> json_response(404)
      end)
    end
  end

  describe "deactivate employee" do
    setup %{conn: conn} do
      party = insert(:prm, :party, tax_id: "22222222250")
      insert(:prm, :party_user, party: party)
      insert(:prm, :party_user, party: party)
      legal_entity = insert(:prm, :legal_entity)
      doctor = insert(:prm, :employee, legal_entity: legal_entity, party: party)

      pharmacist =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          party: party,
          employee_type: Employee.type(:pharmacist)
        )

      {:ok, %{conn: conn, legal_entity: legal_entity, doctor: doctor, pharmacist: pharmacist}}
    end

    test "deactivate employee admin suspend contracts", %{conn: conn, legal_entity: legal_entity} do
      expect(KafkaMock, :publish_deactivate_declaration_event, fn %{"reason" => "auto_employee_deactivate"} ->
        :ok
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      msp()
      party = insert(:prm, :party)
      employee = insert(:prm, :employee, legal_entity: legal_entity, employee_type: "ADMIN", party: party)
      employee2 = insert(:prm, :employee, party: party)

      contract = insert(:prm, :capitation_contract, contractor_owner: employee)
      contract2 = insert(:prm, :capitation_contract, contractor_owner: employee2)

      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 200)
      contract = PRMRepo.get(CapitationContract, contract.id)
      contract2 = PRMRepo.get(CapitationContract, contract2.id)

      assert contract.is_suspended
      refute contract2.is_suspended
    end

    test "deactivate employee", %{conn: conn, legal_entity: legal_entity} do
      expect(KafkaMock, :publish_deactivate_declaration_event, fn %{"reason" => "auto_employee_deactivate"} ->
        :ok
      end)

      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)

      msp()
      employee = insert(:prm, :employee, legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 200)
    end

    test "with invalid transitions condition", %{conn: conn, legal_entity: legal_entity} do
      msp()
      employee = insert(:prm, :employee, legal_entity: legal_entity, status: "DEACTIVATED")
      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Employee is DEACTIVATED and cannot be updated."
    end

    test "can't deactivate OWNER", %{conn: conn, legal_entity: legal_entity} do
      msp()

      employee =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          employee_type: Employee.type(:owner)
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Owner can’t be deactivated"
    end

    test "can't deactivate PHARMACY OWNER", %{conn: conn, legal_entity: legal_entity} do
      msp()
      party = insert(:prm, :party, birth_date: ~D[1990-01-01], tax_id: "2222222225")

      employee =
        insert(
          :prm,
          :employee,
          party: party,
          legal_entity: legal_entity,
          employee_type: Employee.type(:pharmacy_owner)
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn_resp = patch(conn, employee_path(conn, :deactivate, employee.id))

      assert json_response(conn_resp, 409)["error"]["message"] == "Pharmacy owner can’t be deactivated"
    end

    test "successful doctor", %{conn: conn, doctor: doctor, legal_entity: legal_entity} do
      msp()
      set_mox_global()
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      expect_delete_user_role(:ok, 2)

      expect(MithrilMock, :delete_apps_by_user_and_client, 2, fn _, _, _ ->
        {:ok, %{"data" => nil}}
      end)

      expect(MithrilMock, :delete_tokens_by_user_and_client, 2, fn _, _, _ ->
        {:ok, %{"data" => nil}}
      end)

      expect(KafkaMock, :publish_deactivate_declaration_event, fn %{"reason" => "auto_employee_deactivate"} ->
        :ok
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, employee_path(conn, :deactivate, doctor.id))

      resp = json_response(conn, 200)
      refute resp["is_active"]
    end

    test "successful pharmacist", %{conn: conn, pharmacist: pharmacist, legal_entity: legal_entity} do
      msp()
      set_mox_global()
      expect(KafkaMock, :publish_to_event_manager, fn _ -> :ok end)
      expect_delete_user_role(:ok, 2)

      expect(MithrilMock, :delete_apps_by_user_and_client, 2, fn _, _, _ ->
        {:ok, %{"data" => nil}}
      end)

      expect(MithrilMock, :delete_tokens_by_user_and_client, 2, fn _, _, _ ->
        {:ok, %{"data" => nil}}
      end)

      expect(KafkaMock, :publish_deactivate_declaration_event, fn %{"reason" => "auto_employee_deactivate"} ->
        :ok
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, employee_path(conn, :deactivate, pharmacist.id))

      resp = json_response(conn, 200)
      refute resp["is_active"]
    end

    test "not found", %{conn: conn} do
      msp()

      assert conn
             |> put_client_id_header()
             |> patch(employee_path(conn, :deactivate, UUID.generate()))
             |> json_response(404)
    end
  end

  describe "get employee users" do
    test "success", %{conn: conn} do
      party_user = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, party: party_user.party, legal_entity: legal_entity)

      assert %{"party" => party, "legal_entity_id" => _} =
               conn
               |> put_client_id_header(legal_entity.id)
               |> get(employee_path(conn, :employee_users, employee.id))
               |> json_response(200)
               |> Map.get("data")

      assert party_user.party.tax_id == party["tax_id"]
      assert [%{"user_id" => party_user.user_id}] == party["users"]
    end

    test "not found", %{conn: conn} do
      assert conn
             |> put_client_id_header(UUID.generate())
             |> get(employee_path(conn, :employee_users, UUID.generate()))
             |> json_response(404)
    end
  end
end
