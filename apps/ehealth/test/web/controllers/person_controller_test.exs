defmodule EHealth.Web.PersonControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias Ecto.UUID
  alias EHealth.MockServer

  @moduletag :with_client_id

  defmodule MPIServer do
    @moduledoc false

    use MicroservicesHelper

    Plug.Router.get "/persons" do
      Plug.Conn.send_resp(conn, 200, Poison.encode!(%{"data" => [], "paging" => %{"total_pages" => 2}}))
    end
  end

  setup do
    System.put_env("MPI_ENDPOINT", "http://localhost:4040/")
    {:ok, port, ref} = start_microservices(MPIServer)

    on_exit(fn ->
      stop_microservices(ref)
    end)

    {:ok, %{port: port}}
  end

  describe "get person declaration" do
    test "MSP can see own declaration", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      insert(:prm, :employee, id: "7488a646-e31f-11e4-aace-600308960662", legal_entity: legal_entity)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200"))
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert Map.has_key?(data, "person")
      assert Map.has_key?(data, "employee")
      assert Map.has_key?(data, "division")
      assert Map.has_key?(data, "legal_entity")
    end

    test "MSP can't see not own declaration", %{conn: conn} do
      conn = get(conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200"))
      assert 403 == json_response(conn, 403)["meta"]["code"]
    end

    test "NHS ADMIN can see any employees declarations", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: MockServer.get_client_admin())
      insert(:prm, :employee, id: "7488a646-e31f-11e4-aace-600308960662", legal_entity: legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375200"))

      response = json_response(conn, 200)
      assert 200 == response["meta"]["code"]
      # TODO: need more assertions on data
      assert response["data"]["declaration_request_id"]
    end

    test "invalid declarations amount", %{conn: conn} do
      conn = get(conn, person_path(conn, :person_declarations, "7cc91a5d-c02f-41e9-b571-1ea4f2375400"))
      assert 400 == json_response(conn, 400)["meta"]["code"]
    end

    test "declaration not found", %{conn: conn} do
      conn = get(conn, person_path(conn, :person_declarations, UUID.generate()))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end
  end

  describe "reset authentication method to NA" do
    test "success", %{conn: conn} do
      conn = patch(conn, person_path(conn, :reset_authentication_method, MockServer.get_active_person()))
      assert [%{"type" => "NA"}] == json_response(conn, 200)["data"]["authentication_methods"]
    end

    test "person not found", %{conn: conn} do
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
      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string"
        })

      assert response = json_response(conn, 200)
      assert 2 == Enum.count(response["data"])
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

    test "too many persons matched", %{conn: conn, port: port} do
      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}/")

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
      conn =
        get(conn, person_path(conn, :search_persons), %{
          birth_date: "1990-01-01",
          first_name: "string",
          last_name: "string",
          phone_number: "+380631111111"
        })

      assert response = json_response(conn, 200)
      assert 2 == Enum.count(response["data"])
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
end
