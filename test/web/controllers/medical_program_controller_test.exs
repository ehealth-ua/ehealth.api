defmodule EHealth.Web.MedicalProgramControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "list medical programs" do
    test "search by id", %{conn: conn} do
      %{id: id} = insert(:prm, :medical_program)
      insert(:prm, :medical_program)
      conn = put_client_id_header(conn)
      conn = get conn, medical_program_path(conn, :index), %{"id" => id}
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert id == Map.get(hd(resp), "id")
    end

    test "search by name", %{conn: conn} do
      insert(:prm, :medical_program, name: "test")
      insert(:prm, :medical_program, name: "other")
      conn = put_client_id_header(conn)
      conn = get conn, medical_program_path(conn, :index), %{"name" => "te"}
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert "test" == Map.get(hd(resp), "name")
    end

    test "search by is_active", %{conn: conn} do
      %{id: id} = insert(:prm, :medical_program, is_active: true)
      insert(:prm, :medical_program, is_active: false)
      conn = put_client_id_header(conn)
      conn = get conn, medical_program_path(conn, :index), %{"is_active" => true}
      resp = json_response(conn, 200)["data"]
      assert 1 == length(resp)
      assert id == Map.get(hd(resp), "id")
      assert Map.get(hd(resp), "is_active")
    end

    test "search by all possible options", %{conn: conn} do
      %{id: id} = insert(:prm, :medical_program, name: "some name", is_active: true)
      insert(:prm, :medical_program, is_active: false)
      conn = put_client_id_header(conn)
      conn = get conn, medical_program_path(conn, :index), %{"is_active" => true, "name" => "some"}
      resp = json_response(conn, 200)
      data = resp["data"]
      assert 1 == length(data)
      assert id == Map.get(hd(data), "id")
      assert Map.get(hd(data), "is_active")
      assert "some name" == Map.get(hd(data), "name")

      schema =
        "test/data/medical_program/list_medical_programs_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end
  end

  describe "create medical program" do
    test "invalid name", %{conn: conn} do
      conn = put_client_id_header(conn)
      conn = post conn, medical_program_path(conn, :create)
      resp = json_response(conn, 422)
      assert %{"error" => %{"invalid" => [%{"entry" => "$.name"}]}} = resp
    end

    test "success create medical program", %{conn: conn} do
      conn = put_client_id_header(conn)
      conn = post conn, medical_program_path(conn, :create), name: "test"
      resp = json_response(conn, 201)

      schema =
        "test/data/medical_program/create_medical_program_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      %{id: id} = insert(:prm, :medical_program)
      conn = put_client_id_header(conn)
      conn = get conn, medical_program_path(conn, :show, id)
      resp = json_response(conn, 200)["data"]
      assert id == resp["id"]

      schema =
        "test/data/medical_program/get_medical_program_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp)
    end

    test "fail", %{conn: conn} do
      conn = put_client_id_header(conn)
      assert_raise Ecto.NoResultsError, fn ->
        get conn, medical_program_path(conn, :show, Ecto.UUID.generate())
      end
    end
  end
end
