defmodule EHealth.Web.MedicalProgramControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

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
end
