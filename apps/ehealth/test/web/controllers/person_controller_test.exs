defmodule EHealth.Web.PersonControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox
  alias Ecto.UUID
  alias EHealth.MockServer

  @moduletag :with_client_id

  setup :verify_on_exit!

  describe "get person declaration" do
    test "MSP can see own declaration", %{conn: conn} do
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

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
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
      status = 200

      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
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

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
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
        get_person(id, 200, %{"authentication_methods" => [%{"type" => "NA"}]})
      end)

      conn = patch(conn, person_path(conn, :reset_authentication_method, MockServer.get_active_person()))
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
      conn = get(conn, person_path(conn, :search_persons))
      assert response = json_response(conn, 422)

      assert %{
               "error" => %{
                 "invalid" => [%{"entry" => "$.birth_date"}, %{"entry" => "$.first_name"}, %{"entry" => "$.last_name"}]
               }
             } = response
    end

    test "no first_name and last_name", %{conn: conn} do
      conn = get(conn, person_path(conn, :search_persons), %{birth_date: "1990-01-01"})
      assert response = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.first_name"}, %{"entry" => "$.last_name"}]}} = response
    end

    test "success search age > 16", %{conn: conn} do
      expect(MPIMock, :search, fn params, _headers ->
        get_persons(params)
      end)

      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })

      assert response = json_response(conn, 200)
      assert 1 == Enum.count(response["data"])
      expected_keys = ~w(
        birth_country
        birth_date
        birth_settlement
        first_name
        id
        last_name
        merged_ids
        second_name)
      assert expected_keys == Map.keys(hd(response["data"]))
    end

    test "invalid phone number", %{conn: conn} do
      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string",
          phone_number: "invalid"
        })

      assert response = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.phone_number"}]}} = response
    end

    test "too many persons matched", %{conn: conn} do
      expect(MPIMock, :search, fn _params, _headers ->
        {:ok, %{"data" => [], "paging" => %{"total_pages" => 2}}}
      end)

      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })

      assert response = json_response(conn, 403)

      assert %{
               "error" => %{
                 "message" =>
                   "This API method returns only exact match results, please retry with more specific search parameters"
               }
             } = response
    end

    test "success search age > 16 with phone_number", %{conn: conn} do
      expect(MPIMock, :search, fn params, _headers ->
        get_persons(params)
      end)

      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string",
          phone_number: "+380631111111"
        })

      assert response = json_response(conn, 200)
      assert 1 == Enum.count(response["data"])
      expected_keys = ~w(
        birth_country
        birth_date
        birth_settlement
        first_name
        id
        last_name
        merged_ids
        phones
        second_name)
      assert expected_keys == Map.keys(hd(response["data"]))
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
        |> Poison.encode!()
        |> Poison.decode!()
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

    person =
      person
      |> Poison.encode!()
      |> Poison.decode!()

    {:ok, %{"data" => [person], "paging" => %{"total_pages" => 1}}}
  end

  defp get_person(id, response_status, params \\ %{}) do
    params = Map.put(params, :id, id)
    person = build(:person, params)

    person =
      person
      |> Poison.encode!()
      |> Poison.decode!()

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end
end
