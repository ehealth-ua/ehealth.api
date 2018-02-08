defmodule EHealth.Web.MisControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "get employee_id by employee_request_id" do
    test "success", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee)
      employee_request = insert(:il, :employee_request, employee_id: employee.id)

      conn = put_client_id_header(conn, legal_entity.id)
      conn = get(conn, mis_path(conn, :employee_request, employee_request.id))
      assert res = json_response(conn, 200)

      assert %{
               "id" => employee_request.id,
               "employee_id" => employee_request.employee_id,
               "status" => employee_request.status,
               "updated_at" => NaiveDateTime.to_iso8601(employee_request.updated_at)
             } == res["data"]
    end
  end
end
