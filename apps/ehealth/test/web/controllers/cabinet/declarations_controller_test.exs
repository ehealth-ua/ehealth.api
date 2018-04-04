defmodule EHealth.Web.Cabinet.DeclarationsControllerTest do
  @moduledoc false
  use EHealth.Web.ConnCase, async: false
  import Mox

  alias EHealth.MockServer

  defmodule MithrilServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/admin/clients/c8912855-21c3-4771-ba18-bcd80user_id/details" do
      response =
        %{"client_type_name" => "CABINET"}
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/c8912855-21c3-4771-ba18-bcd80user_id" do
      response =
        %{
          "id" => "c8912855-21c3-4771-ba18-bcd80user_id",
          "person_id" => "c8912855-21c3-4771-ba18-bc0person_id",
          "block_reason" => nil,
          "email" => "email@example.com",
          "is_blocked" => false,
          "settings" => %{},
          "tax_id" => "12341234"
        }
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MpiServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/persons/c8912855-21c3-4771-ba18-bc0person_id" do
      response =
        :person
        |> build(id: "c8912855-21c3-4771-ba18-bc0person_id")
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  @user_id "c8912855-21c3-4771-ba18-bcd80user_id"
  @person_id "c8912855-21c3-4771-ba18-bc0person_id"
  @legal_entity_id "edac9408-0998-4184-b64c-34eb9f27e3ba"
  @employee_id "9739fb7d-5aa9-4b6b-95a2-4121d0459c47"
  @division_id "1bb33d3d-ce51-456d-97ac-26d51d9e08bb"
  @declaration_id "1bb33d3d-ce51-456d-97ac-26d51d9e0dd1"
  @declaration_id2 "1bb33d3d-ce51-456d-97ac-26d51d9e0dd2"

  setup do
    insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})
    legal_entity = insert(:prm, :legal_entity, %{id: @legal_entity_id})
    insert(:prm, :employee, %{id: @employee_id, legal_entity: legal_entity})
    insert(:prm, :division, %{id: @division_id})

    register_mircoservices_for_tests([
      {MpiServer, "MPI_ENDPOINT"},
      {MithrilServer, "OAUTH_ENDPOINT"}
    ])

    expect(OPSMock, :get_declarations, fn _params, _headers ->
      declaration_data = [
        id: @declaration_id,
        person_id: @person_id,
        employee_id: @employee_id,
        legal_entity_id: @legal_entity_id,
        division_id: @division_id
      ]

      declaration_data2 = [id: @declaration_id2, person_id: @person_id, employee_id: @employee_id]

      response =
        [
          :declaration |> build(declaration_data) |> convert_atom_keys_to_strings(),
          :declaration |> build(declaration_data2) |> convert_atom_keys_to_strings()
        ]
        |> MockServer.wrap_response_with_paging()

      {:ok, response}
    end)

    :ok
  end

  test "searches person declarations in cabinet", %{conn: conn} do
    response = conn |> send_list_declaration_request() |> json_response(200)

    assert %{"data" => response_data, "paging" => %{"total_entries" => 2}, "meta" => _} = response
    assert [@declaration_id, @declaration_id2] = Enum.map(response_data, & &1["id"])
  end

  test "rejects to search person declaration due to request validation", %{conn: conn} do
    assert %{status: 422} = send_list_declaration_request(conn, start_year: "20IZ")
  end

  defp send_list_declaration_request(conn, params \\ []) do
    conn
    |> put_req_header("x-consumer-id", @user_id)
    |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: @user_id}))
    |> get(cabinet_declarations_path(conn, :list_declarations), params)
  end
end
