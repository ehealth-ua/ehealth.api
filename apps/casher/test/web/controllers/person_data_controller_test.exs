defmodule Casher.Web.PersonDataControllerTest do
  @moduledoc false

  use Casher.Web.ConnCase, async: false
  import Mox

  alias Casher.Redis
  alias Casher.StorageKeys
  alias Ecto.UUID

  describe "get person data" do
    test "success by user_id and client_id", %{conn: conn} do
      %{user_id: user_id, client_id: client_id, person_ids: person_ids} = prepare_success_path()
      request_data = %{"client_id" => client_id, "user_id" => user_id}

      expect(OPSMock, :get_person_ids, fn _employee_ids, _headers ->
        {:ok, %{"data" => %{"person_ids" => person_ids}}}
      end)

      person_ids_resp =
        conn
        |> get(person_data_path(conn, :get_person_data, request_data))
        |> json_response(200)
        |> get_in(["data", "person_ids"])

      assert person_ids_resp == person_ids
      assert {:ok, ^person_ids} = Redis.get(StorageKeys.person_data(user_id, client_id))
    end

    test "success by employee_id", %{conn: conn} do
      %{employee: employee, user_id: user_id, client_id: client_id, person_ids: person_ids} = prepare_success_path()

      expect(OPSMock, :get_person_ids, fn _employee_ids, _headers ->
        {:ok, %{"data" => %{"person_ids" => person_ids}}}
      end)

      person_ids_resp =
        conn
        |> get(person_data_path(conn, :get_person_data, %{"employee_id" => employee.id}))
        |> json_response(200)
        |> get_in(["data", "person_ids"])

      assert person_ids_resp == person_ids
      assert {:ok, ^person_ids} = Redis.get(StorageKeys.person_data(user_id, client_id))
    end
  end

  describe "update person data" do
    test "success by user_id and client_id", %{conn: conn} do
      %{user_id: user_id, client_id: client_id, person_ids: person_ids} = prepare_success_path()
      request_data = %{"client_id" => client_id, "user_id" => user_id}

      expect(OPSMock, :get_person_ids, fn _employee_ids, _headers ->
        {:ok, %{"data" => %{"person_ids" => person_ids}}}
      end)

      assert {:error, :not_found} = Redis.get(StorageKeys.person_data(user_id, client_id))

      assert conn
             |> patch(person_data_path(conn, :update_person_data, request_data))
             |> json_response(200)

      assert {:ok, ^person_ids} = Redis.get(StorageKeys.person_data(user_id, client_id))
    end

    test "success by employee_id", %{conn: conn} do
      %{id: client_id} = legal_entity = insert(:prm, :legal_entity)
      _party_user = %{user_id: user_id, party: party} = insert(:prm, :party_user)
      employee = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      _employee_2 = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      _employee_3 = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      person_ids = [UUID.generate(), UUID.generate()]

      expect(OPSMock, :get_person_ids, fn _employee_ids, _headers ->
        {:ok, %{"data" => %{"person_ids" => person_ids}}}
      end)

      assert {:error, :not_found} = Redis.get(StorageKeys.person_data(user_id, client_id))

      assert conn
             |> patch(person_data_path(conn, :update_person_data, %{"employee_id" => employee.id}))
             |> json_response(200)

      assert {:ok, ^person_ids} = Redis.get(StorageKeys.person_data(user_id, client_id))
    end
  end

  @spec prepare_success_path :: map
  defp prepare_success_path do
    %{id: client_id} = legal_entity = insert(:prm, :legal_entity)
    %{user_id: user_id, party: party} = insert(:prm, :party_user)
    employee = insert(:prm, :employee, party: party, legal_entity: legal_entity)
    person_ids = [UUID.generate(), UUID.generate()]

    %{person_ids: person_ids, employee: employee, user_id: user_id, client_id: client_id}
  end
end
