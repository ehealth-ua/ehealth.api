defmodule EHealth.Web.Cabinet.DeclarationControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.MockServer
  alias Ecto.UUID
  import Mox

  setup :verify_on_exit!

  @person_id "0c65d15b-32b4-4e82-b53d-0572416d890e"
  @legal_entity_id "edac9408-0998-4184-b64c-34eb9f27e3ba"
  @employee_id "9739fb7d-5aa9-4b6b-95a2-4121d0459c47"
  @division_id "1bb33d3d-ce51-456d-97ac-26d51d9e08bb"
  @declaration_id "1bb33d3d-ce51-456d-97ac-26d51d9e0dd1"
  @declaration_id2 "1bb33d3d-ce51-456d-97ac-26d51d9e0dd2"

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
      cabinet(3)
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity)
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      expect(MithrilMock, :get_user_by_id, fn _, _ ->
        {:ok, %{"data" => %{"person_id" => @person_id, "tax_id" => "12341234", "is_blocked" => false}}}
      end)

      {declaration, _} =
        get_declaration(
          %{
            id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: @person_id
          },
          200
        )

      expect(OPSMock, :terminate_declaration, fn id, _params, _headers ->
        declaration =
          build(
            :declaration,
            person_id: @person_id,
            id: id,
            status: "terminated"
          )
          |> Map.put("reason", "manual_person")

        resp =
          %{"data" => declaration, "meta" => %{"code" => 200, "type" => "list"}}
          |> Jason.encode!()
          |> Jason.decode!()

        {:ok, resp}
      end)

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{addresses: get_person_addresses()})
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{addresses: get_person_addresses()})
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> patch(cabinet_declarations_path(conn, :terminate_declaration, "0cd6a6f0-9a71-4aa7-819d-6c158201a282"))

      assert %{"data" => %{"id" => "0cd6a6f0-9a71-4aa7-819d-6c158201a282", "status" => "terminated"}} =
               json_response(conn, 200)
    end
  end

  test "searches person declarations in cabinet", %{conn: conn} do
    expect(MPIMock, :person, fn id, _headers ->
      get_person(id, 200, %{tax_id: "12341234"})
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

  defp get_declaration(params, response_status) do
    declaration = build(:declaration, params)
    declaration_id = declaration.id

    declaration =
      declaration
      |> Jason.encode!()
      |> Jason.decode!()

    {{:ok, %{"data" => declaration, "meta" => %{"code" => response_status}}}, declaration_id}
  end

  defp send_list_declaration_request(conn, params \\ []) do
    conn
    |> put_consumer_id_header(UUID.generate())
    |> put_client_id_header(UUID.generate())
    |> get(cabinet_declarations_path(conn, :index), params)
  end

  defp get_person(id, response_status, params) do
    params = Map.put(params, :id, id)
    person = string_params_for(:person, params)

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end

  defp get_person_addresses do
    [
      build(:address, %{"type" => "REGISTRATION"}),
      build(:address, %{"type" => "RESIDENCE"})
    ]
  end
end
