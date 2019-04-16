defmodule EHealth.Web.Cabinet.DeclarationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox

  alias EHealth.MockServer
  alias Ecto.UUID

  setup :verify_on_exit!

  @person_id "0c65d15b-32b4-4e82-b53d-0572416d890e"
  @legal_entity_id "edac9408-0998-4184-b64c-34eb9f27e3ba"
  @employee_id "9739fb7d-5aa9-4b6b-95a2-4121d0459c47"
  @division_id "1bb33d3d-ce51-456d-97ac-26d51d9e08bb"
  @declaration_id "1bb33d3d-ce51-456d-97ac-26d51d9e0dd1"
  @declaration_id2 "1bb33d3d-ce51-456d-97ac-26d51d9e0dd2"

  @status_terminated "terminated"

  setup do
    legal_entity = insert(:prm, :legal_entity, %{id: @legal_entity_id})
    insert(:prm, :employee, %{id: @employee_id, legal_entity: legal_entity})
    insert(:prm, :division, %{id: @division_id})

    insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})

    :ok
  end

  describe "terminate declaration" do
    test "success terminate declaration", %{conn: conn} do
      id = UUID.generate()
      consumer_id = UUID.generate()
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, party: party, legal_entity: legal_entity)
      insert(:prm, :division, legal_entity: legal_entity)
      person = build(:person, id: @person_id)
      declaration = build(:declaration, id: id, person_id: @person_id)

      cabinet(2)

      expect(MithrilMock, :get_user_by_id, fn ^consumer_id, _ ->
        {:ok,
         %{"data" => %{"id" => consumer_id, "person_id" => @person_id, "tax_id" => "12341234", "is_blocked" => false}}}
      end)

      expect(RPCWorkerMock, :run, fn "ops", OPS.Rpc, :get_declaration, _ -> {:ok, declaration} end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, _ -> {:ok, person} end)

      expect(RPCWorkerMock, :run, fn "ops", OPS.Rpc, :terminate_declaration, [id, _] ->
        assert id == declaration.id
        {:ok, %{declaration | status: @status_terminated}}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] -> {:ok, build(:person, id: id)} end)

      assert resp =
               conn
               |> put_consumer_id_header(consumer_id)
               |> put_client_id_header(legal_entity.id)
               |> patch(cabinet_declarations_path(conn, :terminate_declaration, id))
               |> json_response(200)

      assert %{"data" => %{"id" => ^id, "status" => @status_terminated}} = resp
    end
  end

  test "searches person declarations in cabinet", %{conn: conn} do
    expect(RPCWorkerMock, :run, fn _, _, :get_person_by_id, [id] ->
      {:ok, build(:person, id: id, tax_id: "12341234")}
    end)

    expect(MithrilMock, :get_user_by_id, fn _, _ ->
      {:ok, %{"data" => %{"person_id" => @person_id, "tax_id" => "12341234", "is_blocked" => false}}}
    end)

    expect(OPSMock, :get_declarations, fn _params, _headers ->
      response =
        [
          string_params_for(
            :declaration,
            id: @declaration_id,
            person_id: @person_id,
            employee_id: @employee_id,
            legal_entity_id: @legal_entity_id,
            division_id: @division_id
          ),
          string_params_for(
            :declaration,
            id: @declaration_id2,
            person_id: @person_id,
            employee_id: @employee_id,
            legal_entity_id: @legal_entity_id,
            division_id: @division_id
          )
        ]
        |> MockServer.wrap_response_with_paging()

      {:ok, response}
    end)

    cabinet()
    response = conn |> send_list_declaration_request() |> json_response(200)
    verify!()

    assert %{"data" => response_data, "paging" => %{"total_entries" => 2}, "meta" => _} = response
    assert [@declaration_id, @declaration_id2] = Enum.map(response_data, & &1["id"])

    assert_json_schema(response_data, "../core/specs/json_schemas/cabinet/declarations/index_response.json")
  end

  test "rejects to search person declaration due to request validation", %{conn: conn} do
    cabinet()
    assert %{status: 422} = send_list_declaration_request(conn, start_year: "20IZ")
  end

  defp send_list_declaration_request(conn, params \\ []) do
    conn
    |> put_consumer_id_header(UUID.generate())
    |> put_client_id_header(UUID.generate())
    |> get(cabinet_declarations_path(conn, :index), params)
  end
end
