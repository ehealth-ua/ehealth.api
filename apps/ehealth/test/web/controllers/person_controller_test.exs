defmodule EHealth.Web.PersonControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID

  @moduletag :with_client_id

  setup :verify_on_exit!

  describe "get person declaration" do
    test "MSP can see own declaration", %{conn: conn} do
      msp()
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          1,
          status
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, person_path(conn, :person_declarations, person_id))
      data = json_response(conn, status)["data"]
      assert is_map(data)
      assert Map.has_key?(data, "person")
      assert Map.has_key?(data, "employee")
      assert Map.has_key?(data, "division")
      assert Map.has_key?(data, "legal_entity")
      assert Map.has_key?(data, "declaration_number")
    end

    test "MSP can't see not own declaration", %{conn: conn} do
      msp()
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          200,
          %{2 => %{status: "terminated"}}
        )
      end)

      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, person_path(conn, :person_declarations, person_id))
      assert 403 == json_response(conn, 403)["meta"]["code"]
    end

    test "NHS ADMIN can see any employees declarations", %{conn: conn} do
      admin()
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          status,
          %{2 => %{status: "terminated"}}
        )
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id)}
      end)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, person_path(conn, :person_declarations, person_id))

      response = json_response(conn, status)
      assert status == response["meta"]["code"]
      # TODO: need more assertions on data
      assert response["data"]["declaration_request_id"]
    end

    test "invalid declarations amount", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)
      person_id = UUID.generate()

      expect(OPSMock, :get_declarations, fn %{"person_id" => person_id}, _headers ->
        get_declarations(
          %{
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: person_id
          },
          2,
          200
        )
      end)

      conn = get(conn, person_path(conn, :person_declarations, person_id))
      assert 400 == json_response(conn, 400)["meta"]["code"]
    end

    test "declaration not found", %{conn: conn} do
      expect(OPSMock, :get_declarations, fn _params, _headers ->
        {:ok,
         %{
           "data" => [],
           "meta" => %{"code" => 200},
           "paging" => %{
             "page_number" => 1,
             "page_size" => 50,
             "total_entries" => 0,
             "total_pages" => 1
           }
         }}
      end)

      conn = get(conn, person_path(conn, :person_declarations, UUID.generate()))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  describe "reset authentication method to NA" do
    test "success", %{conn: conn} do
      expect(MPIMock, :reset_person_auth_method, fn id, _headers ->
        get_person(id, 200, %{:authentication_methods => [%{"type" => "NA"}]})
      end)

      conn = patch(conn, person_path(conn, :reset_authentication_method, UUID.generate()))
      assert [%{"type" => "NA"}] == json_response(conn, 200)["data"]["authentication_methods"]
    end

    test "person not found", %{conn: conn} do
      expect(MPIMock, :reset_person_auth_method, fn id, _headers ->
        get_person(id, 404)
      end)

      conn = patch(conn, person_path(conn, :reset_authentication_method, UUID.generate()))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  describe "search persons" do
    test "no birth_date", %{conn: conn} do
      resp =
        conn
        |> get(person_path(conn, :search_persons))
        |> json_response(422)

      assert %{
               "error" => %{
                 "invalid" => [%{"entry" => "$.birth_date"}, %{"entry" => "$.first_name"}, %{"entry" => "$.last_name"}]
               }
             } = resp
    end

    test "no first_name and last_name", %{conn: conn} do
      resp =
        conn
        |> get(person_path(conn, :search_persons), %{birth_date: "1990-01-01"})
        |> json_response(422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.first_name"}, %{"entry" => "$.last_name"}]}} = resp
    end

    test "success search age > 16", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [params, nil, [read_only: true, paginate: true]] ->
        get_persons(params)
      end)

      resp =
        conn
        |> get(person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })
        |> json_response(200)

      assert 1 == Enum.count(resp["data"])
      expected_keys = ~w(
        birth_country
        birth_date
        birth_settlement
        first_name
        id
        last_name
        master_persons
        merged_persons
        second_name)
      assert expected_keys == Map.keys(hd(resp["data"]))
    end

    test "success search with unzr", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [params, nil, [read_only: true, paginate: true]] ->
        get_persons(params)
      end)

      resp =
        conn
        |> get(person_path(conn, :search_persons), %{
          unzr: "19930823-01234",
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })
        |> json_response(200)

      assert 1 == Enum.count(resp["data"])
      expected_keys = ~w(
        birth_country
        birth_date
        birth_settlement
        first_name
        id
        last_name
        master_persons
        merged_persons
        second_name
        unzr
        )
      assert expected_keys == Map.keys(hd(resp["data"]))
    end

    test "invalid phone number", %{conn: conn} do
      resp =
        conn
        |> get(person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string",
          phone_number: "invalid"
        })
        |> json_response(422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.phone_number"}]}} = resp
    end

    test "too many persons matched", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [
                                       %{"birth_date" => _, "first_name" => _, "last_name" => _, "status" => _},
                                       nil,
                                       [read_only: true, paginate: true]
                                     ] ->
        {:ok, %{data: [], paging: %{total_pages: 2}}}
      end)

      resp =
        conn
        |> get(person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })
        |> json_response(403)

      assert %{
               "error" => %{
                 "message" =>
                   "This API method returns only exact match results, please retry with more specific search parameters"
               }
             } = resp
    end

    test "success search age > 16 with phone_number", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn "mpi",
                                     MPI.Rpc,
                                     :search_persons,
                                     [params, nil, [read_only: true, paginate: true]] ->
        get_persons(params)
      end)

      resp =
        conn
        |> get(person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string",
          phone_number: "+380631111111"
        })
        |> json_response(200)

      assert 1 == Enum.count(resp["data"])
      expected_keys = ~w(
        birth_country
        birth_date
        birth_settlement
        first_name
        id
        last_name
        master_persons
        merged_persons
        phones
        second_name)
      assert expected_keys == Map.keys(hd(resp["data"]))
    end
  end

  defp get_declarations(params, count, response_status, opts \\ %{}) when count > 0 do
    declarations =
      Enum.map(1..count, fn index ->
        current_params =
          if Map.has_key?(opts, index) do
            Map.merge(params, Map.get(opts, index))
          else
            params
          end

        declaration = build(:declaration, current_params)

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

  defp get_persons(params) do
    person = build(:person, params)
    {:ok, %{data: [person], paging: %{total_pages: 1}}}
  end

  defp get_person(id, response_status, params \\ %{}) do
    params = Map.put(params, :id, id)
    person = build(:person, params)

    person =
      person
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end
end
