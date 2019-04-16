defmodule EHealth.Web.DeclarationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Core.Utils.TypesConverter, only: [strings_to_keys: 1]
  import Mox

  alias Ecto.Changeset
  alias Core.Declarations.Declaration
  alias Ecto.UUID

  @status_active "active"
  @status_pending "pending_verification"
  @status_rejected "rejected"

  setup :verify_on_exit!

  describe "list declarations" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, edrpou: "37367387"))
      json_response(conn, 401)
    end

    test "by person_id", %{conn: conn} do
      msp()
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          status
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [
                                       %{"ids" => ids},
                                       ~w(id first_name last_name second_name birth_date)a,
                                       [read_only: true]
                                     ] ->
        get_rpc_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, person_id: UUID.generate()))

      resp =
        conn
        |> json_response(status)
        |> Map.get("data")

      assert 2 == Enum.count(resp)

      Enum.each(resp, fn elem ->
        assert Map.has_key?(elem, "reason")
        assert Map.has_key?(elem, "reason_description")
        assert Map.has_key?(elem, "declaration_number")
        assert Map.get(elem["person"], "birth_date", nil) != nil
      end)
    end

    test "empty by person_id", %{conn: conn} do
      msp()
      status = 200

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok, %{"data" => [], "meta" => %{"code" => status}}}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, person_id: UUID.generate()))
      assert [] = json_response(conn, status)["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id with empty declarations list", %{conn: conn} do
      msp()
      status = 200

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "meta" => %{"code" => status},
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, edrpou: "37367387"))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id and invalid legal_entity_id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: UUID.generate()))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      msp()
      status = 200

      division = insert(:prm, :division)
      legal_entity = insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      expect(OPSMock, :get_declarations, fn _params, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          1,
          status
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [
                                       %{"ids" => ids},
                                       ~w(id first_name last_name second_name birth_date)a,
                                       [read_only: true]
                                     ] ->
        get_rpc_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity.id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      mis()
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"legal_entity_id" => legal_entity_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity_id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          status
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [
                                       %{"ids" => ids},
                                       ~w(id first_name last_name second_name birth_date)a,
                                       [read_only: true]
                                     ] ->
        get_rpc_persons(ids)
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity.id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      nhs()
      status = 200

      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      expect(OPSMock, :get_declarations, fn %{"legal_entity_id" => legal_entity_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity_id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          3,
          status
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [
                                       %{"ids" => ids},
                                       ~w(id first_name last_name second_name birth_date)a,
                                       [read_only: true]
                                     ] ->
        get_rpc_persons(ids)
      end)

      %{id: legal_entity_id} = legal_entity
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_path(conn, :index, legal_entity_id: legal_entity_id))
      resp = json_response(conn, status)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 3 == length(resp["data"])
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end
  end

  describe "declaration by id" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:ok, nil} end)
      {declaration, declaration_id} = get_declaration(%{}, 200)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains MSP client_id with undefined declaration id", %{conn: conn} do
      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        nil
      end)

      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get(conn, declaration_path(conn, :show, "226b4182-f9ce-4eda-b6af-43d2de8600a0"))
      json_response(conn, 404)
    end

    test "with x-consumer-metadata that contains MSP client_id with invalid legal_entity_id", %{conn: conn} do
      msp()
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      {declaration, declaration_id} = get_declaration(%{legal_entity_id: legal_entity_id}, 200)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "reason")
      assert Map.has_key?(data, "reason_description")
      assert Map.has_key?(data, "declaration_number")
      assert_declaration_expanded_fields(data)
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      mis()
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert declaration_id == data["id"]
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      nhs()
      legal_entity = insert(:prm, :legal_entity)
      division = insert(:prm, :division)
      insert(:prm, :legal_entity)
      person_id = UUID.generate()

      %{id: employee_id} =
        insert(
          :prm,
          :employee,
          legal_entity: legal_entity,
          division: division
        )

      {declaration, declaration_id} =
        get_declaration(
          %{
            id: person_id,
            legal_entity_id: legal_entity.id,
            division_id: division.id,
            employee_id: employee_id,
            person_id: person_id
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, declaration_path(conn, :show, declaration_id))
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert declaration_id == data["id"]
    end
  end

  def assert_declaration_expanded_fields(declaration) do
    fields = ~W(person employee division legal_entity)
    assert is_map(declaration)
    assert declaration["declaration_request_id"]

    Enum.each(fields, fn field ->
      assert Map.has_key?(declaration, field), "Expected field #{field} not present"
      assert is_map(declaration[field]), "Expected that field #{field} is map"

      assert Enum.any?([:id, "id"], &Map.has_key?(declaration[field], &1)),
             "Expected field #{field}.id not present"

      refute Map.has_key?(declaration, field <> "_id"), "Field #{field}_id should be not present"
    end)
  end

  describe "approve/2 - Happy case" do
    test "it transitions declaration to active status" do
      nhs()
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_pending, legal_entity_id: legal_entity.id)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [id, patch] ->
        assert id == declaration.id
        assert @status_active == patch["status"]
        assert consumer_id == patch["updated_by"]

        {:ok, Map.merge(declaration, strings_to_keys(patch))}
      end)

      assert response =
               build_conn()
               |> put_consumer_id_header(consumer_id)
               |> put_client_id_header(legal_entity.id)
               |> patch("/api/declarations/#{declaration.id}/actions/approve")
               |> json_response(200)

      assert @status_active == response["data"]["status"]
    end
  end

  describe "approve/2 - not owner of declaration" do
    test "a 403 error is returned" do
      msp()

      %{id: declaration_id} = declaration = build(:declaration, status: @status_pending)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: ^declaration_id]] -> {:ok, declaration} end)

      assert build_conn()
             |> put_client_id_header(UUID.generate())
             |> patch("/api/declarations/#{declaration_id}/actions/approve")
             |> json_response(403)
    end
  end

  describe "approve/2 - declaration was inactive" do
    test "a 404 error is returned (as if declaration never existed)" do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> nil end)

      response =
        build_conn()
        |> put_client_id_header(UUID.generate())
        |> patch("/api/declarations/#{UUID.generate()}/actions/approve")

      assert json_response(response, 404)
    end
  end

  describe "approve/2 - could not transition status" do
    test "a 409 error is returned" do
      nhs()

      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_active)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [_, _] ->
        changeset =
          %Declaration{}
          |> Changeset.cast(%{status: @status_pending, updated_by: UUID.generate()}, ~w(status updated_by)a)
          |> Changeset.add_error(:status, "Incorrect status transition.")

        {:error, changeset}
      end)

      response =
        build_conn()
        |> put_consumer_id_header(consumer_id)
        |> put_client_id_header(UUID.generate())
        |> patch("/api/declarations/#{declaration.id}/actions/approve")

      assert json_response(response, 409)
    end
  end

  describe "reject/2 - Happy case" do
    test "it transitions declaration to rejected status" do
      msp()

      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_pending, legal_entity_id: legal_entity.id)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [id, patch] ->
        assert id == declaration.id
        assert @status_rejected == patch["status"]
        assert consumer_id == patch["updated_by"]

        {:ok, Map.merge(declaration, strings_to_keys(patch))}
      end)

      assert response =
               build_conn()
               |> put_consumer_id_header(consumer_id)
               |> put_client_id_header(legal_entity.id)
               |> patch("/api/declarations/#{declaration.id}/actions/reject")
               |> json_response(200)

      assert @status_rejected = response["data"]["status"]
    end
  end

  describe "reject/2 - not owner of declaration" do
    test "a 403 error is returned" do
      msp()
      declaration = build(:declaration, status: @status_pending)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> {:ok, declaration} end)

      assert build_conn()
             |> put_client_id_header(UUID.generate())
             |> patch("/api/declarations/#{declaration.id}/actions/reject")
             |> json_response(403)
    end
  end

  describe "reject/2 - declaration was inactive" do
    test "a 404 error is returned (as if declaration never existed)" do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> nil end)

      assert build_conn()
             |> put_client_id_header(UUID.generate())
             |> patch("/api/declarations/#{UUID.generate()}/actions/reject")
             |> json_response(404)
    end
  end

  describe "reject/2 - could not transition status" do
    test "a 409 error is returned" do
      nhs()

      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_active)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [_, _] ->
        changeset =
          %Declaration{}
          |> Changeset.cast(%{status: @status_pending, updated_by: UUID.generate()}, ~w(status updated_by)a)
          |> Changeset.add_error(:status, "Incorrect status transition.")

        {:error, changeset}
      end)

      response =
        build_conn()
        |> put_consumer_id_header(consumer_id)
        |> put_client_id_header(UUID.generate())
        |> patch("/api/declarations/#{declaration.id}/actions/reject")

      assert json_response(response, 409)
    end
  end

  describe "terminate declarations" do
    test "both params person_id and employee_id passed", %{conn: conn} do
      payload = %{person_id: Ecto.UUID.generate(), employee_id: Ecto.UUID.generate(), reason_description: "lol"}

      conn
      |> put_req_header("x-consumer-id", UUID.generate())
      |> put_client_id_header(UUID.generate())
      |> patch("/api/declarations/terminate", payload)
      |> json_response(422)
    end

    test "terminate by person_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()

      expect(OPSMock, :terminate_person_declarations, fn _, _, _, _, _ ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => %{
             "terminated_declarations" => [%{"reason" => "manual_person", "reason_description" => "Person cheater"}]
           }
         }}
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(legal_entity.id)
        |> patch("/api/declarations/terminate", %{person_id: UUID.generate(), reason_description: "Person cheater"})
        |> json_response(200)

      assert [%{"reason" => "manual_person", "reason_description" => "Person cheater"}] =
               response["data"]["terminated_declarations"]
    end

    test "no declarations by person_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()

      expect(OPSMock, :terminate_person_declarations, fn _, _, _, _, _ ->
        {:ok, %{"meta" => %{"code" => 200}, "data" => %{"terminated_declarations" => []}}}
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(legal_entity.id)
        |> patch("/api/declarations/terminate", %{person_id: "9b6c7be2-278e-4be5-a297-2d009985c404"})
        |> json_response(422)

      assert "Person does not have active declarations" == response["error"]["message"]
    end

    test "terminate by employee_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()

      expect(OPSMock, :terminate_employee_declarations, fn _, _, _, _, _ ->
        {:ok,
         %{
           "meta" => %{"code" => 200},
           "data" => %{
             "terminated_declarations" => [%{"reason" => "manual_employee", "reason_description" => "Employee died"}]
           }
         }}
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(legal_entity.id)
        |> patch("/api/declarations/terminate", %{employee_id: UUID.generate(), reason_description: "Employee died"})
        |> json_response(200)

      assert [%{"reason" => "manual_employee", "reason_description" => "Employee died"}] =
               response["data"]["terminated_declarations"]
    end

    test "no declarations by employee_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()

      expect(OPSMock, :terminate_employee_declarations, fn _, _, _, _, _ ->
        {:ok, %{"meta" => %{"code" => 200}, "data" => %{"terminated_declarations" => []}}}
      end)

      response =
        conn
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(legal_entity.id)
        |> patch("/api/declarations/terminate", %{employee_id: "9b6c7be2-278e-4be5-a297-2d009985c404"})
        |> json_response(422)

      assert "Employee does not have active declarations" == response["error"]["message"]
    end
  end

  defp get_declarations(params, count, response_status) when count > 0 do
    declarations =
      Enum.map(1..count, fn _ ->
        declaration = build(:declaration, params)

        declaration
        |> Jason.encode!()
        |> Jason.decode!()
      end)

    {:ok,
     %{
       "data" => declarations,
       "meta" => %{"code" => response_status},
       "paging" => %{
         "page_number" => 1,
         "page_size" => 50,
         "total_entries" => count,
         "total_pages" => 1
       }
     }}
  end

  defp get_declaration(params, response_status) do
    declaration = build(:declaration, params)
    declaration_id = declaration.id

    declaration =
      declaration
      |> Jason.encode!()
      |> Jason.decode!()

    {{:ok, %{"data" => declaration, "meta" => %{"code" => response_status}}}, declaration_id}
  end

  defp get_persons(params) when is_binary(params) do
    persons =
      Enum.map(String.split(params, ","), fn id ->
        person = build(:person, id: id)

        person
        |> Jason.encode!()
        |> Jason.decode!()
      end)

    {:ok, %{"data" => persons}}
  end

  defp get_rpc_persons(params) when is_binary(params) do
    {:ok, persons} = get_persons(params)
    {:ok, persons["data"]}
  end
end
