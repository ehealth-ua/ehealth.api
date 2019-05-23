defmodule EHealth.Web.V2.EmployeeRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Core.Expectations.Signature
  import Core.Expectations.Man
  import Mox

  setup :verify_on_exit!

  describe "create employee request" do
    test "success", %{conn: conn} do
      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _ ->
        {:ok, "success"}
      end)

      employee_request_params =
        "../core/test/data/employee_doctor_request.json"
        |> File.read!()
        |> Jason.decode!()

      tax_id = "3378115538"
      drfo_signed_content(employee_request_params, tax_id)
      party = insert(:prm, :party, tax_id: tax_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: party)
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      legal_entity = insert(:prm, :legal_entity)
      template()

      insert(
        :prm,
        :division,
        id: employee_request_params["employee_request"]["division_id"],
        legal_entity: legal_entity
      )

      params = %{
        "signed_content" => employee_request_params |> Jason.encode!() |> Base.encode64(),
        "signed_content_encoding" => "base64"
      }

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> post(v2_employee_request_path_path(conn, :create), params)

      assert json_response(conn, 200)
    end
  end
end
