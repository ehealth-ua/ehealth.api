defmodule EHealth.Integraiton.DeclarationRequestCreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  test "creating declaration request", %{conn: conn} do
    declaration_request_params = File.read!("test/data/declaration_request.json")

    conn =
      conn
      |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
      |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
      |> post("/api/declaration_requests", declaration_request_params)

    resp = json_response(conn, 200)

    id = resp["data"]["id"]

    assert to_string(Date.utc_today) == resp["data"]["data"]["start_date"]
    assert {:ok, _} = Date.from_iso8601(resp["data"]["data"]["end_date"])
    assert "NEW" = resp["data"]["status"]
    assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
    assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
    assert %{"number" => "+380508887700", "type" => "OTP"} = resp["data"]["authentication_method_current"]
    assert "<html><body>Printout form for declaration request ##{id}</body></hrml>" ==
      resp["data"]["printout_content"]

    assert [
      %{
        "type" => "Passport",
        "url" => "http://some_resource.com/#{id}/declaration_request_Passport.jpeg"
      },
      %{
        "type" => "SSN",
        "url" => "http://some_resource.com/#{id}/declaration_request_SSN.jpeg"
      }
    ] == resp["data"]["documents"]
  end

  test "employee does not exist", %{conn: conn} do
    wrong_id = "779b3fcc-730e-4128-bd99-77036efa4859"

    declaration_request_params =
      "test/data/declaration_request.json"
      |> File.read!()
      |> Poison.decode!
      |> put_in(["declaration_request", "employee_id"], wrong_id)

    conn =
      conn
      |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
      |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
      |> post("/api/declaration_requests", declaration_request_params)

    resp = json_response(conn, 424)

    error_message = "Error during microservice interaction. \
Accessing http://localhost:4040/employees/#{wrong_id} resulted in 404."
    assert error_message == resp["error"]["message"]
  end
end
