defmodule EHealth.Web.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.SimpleFactory

  alias EHealth.DeclarationRequest

  describe "list declaration requests" do
    test "no legal_entity_id match", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, fixture_params())
      end)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by legal_entity_id", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      employee_id = Ecto.UUID.generate()
      params =
        fixture_params()
        |> put_in([:data, :employee, :id], employee_id)
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index)
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no employee_id match", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      employee_id = Ecto.UUID.generate()
      params =
        fixture_params()
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index, %{employee_id: employee_id})
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by employee_id", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      employee_id = Ecto.UUID.generate()
      params =
        fixture_params()
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
        |> put_in([:data, :employee, :id], employee_id)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index, %{employee_id: employee_id})
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no status match", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      params =
        fixture_params()
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index, %{status: "ACTIVE"})
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by status", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      status = "ACTIVE"
      params =
        fixture_params()
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
        |> put_in([:status], status)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index, %{status: status})
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "match by legal_entity_id, employee_id, status", %{conn: conn} do
      legal_entity_id = Ecto.UUID.generate()
      employee_id = Ecto.UUID.generate()
      status = "ACTIVE"
      params =
        fixture_params()
        |> put_in([:data, :legal_entity, :id], legal_entity_id)
        |> put_in([:data, :employee, :id], employee_id)
        |> put_in([:status], status)
      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declaration_request_path(conn, :index, %{
        status: status,
        employee_id: employee_id
      })
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end
  end

  describe "get declaration request by id" do
    test "get declaration request by invalid id", %{conn: conn} do
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      assert_raise Ecto.NoResultsError, fn ->
        get conn, declaration_request_path(conn, :show, Ecto.UUID.generate())
      end
    end

    test "get declaration request by invalid legal_entity_id", %{conn: conn} do
      %{id: id} = fixture(DeclarationRequest, fixture_params())
      conn = put_client_id_header(conn, Ecto.UUID.generate)
      assert_raise Ecto.NoResultsError, fn ->
        get conn, declaration_request_path(conn, :show, id)
      end
    end

    test "get declaration request by id", %{conn: conn} do
      %{id: id, data: data} = fixture(DeclarationRequest, fixture_params())
      conn = put_client_id_header(conn, get_in(data, [:legal_entity, :id]))
      conn = get conn, declaration_request_path(conn, :show, id)
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
    end
  end

  defp fixture_params do
    uuid = Ecto.UUID.generate()
    %{
      data: %{
        id: Ecto.UUID.generate(),
        start_date: "2017-03-02",
        end_date: "2017-03-02",
        person: %{
          id: Ecto.UUID.generate(),
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
        },
        employee: %{
          id: Ecto.UUID.generate(),
          position: "P6",
          party: %{
            id: Ecto.UUID.generate(),
            first_name: "Петро",
            last_name: "Іванов",
            second_name: "Миколайович",
            email: "email@example.com",
            phones: [
              %{
                type: "MOBILE",
                number: "+380503410870"
              }
            ]
          },
        },
        legal_entity: %{
          id: Ecto.UUID.generate(),
          name: "Клініка Борис",
          short_name: "Борис",
          legal_form: "140",
          edrpou: "5432345432",
        },
        division: %{
          id: Ecto.UUID.generate(),
          name: "Бориспільське відділення Клініки Борис",
          type: "clinic",
        }
      },
      status: "NEW",
      inserted_by: uuid,
      updated_by: uuid,
      authentication_method_current: %{},
      printout_content: "",
    }
  end

  defp assert_count_declaration_request_list(resp, count \\ 0) do
    schema =
      "test/data/declaration_request/index_api_response_schema.json"
      |> File.read!()
      |> Poison.decode!()
    :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
    assert count == length(resp["data"])
  end
end
