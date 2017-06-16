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
        "GET" => "http://some_resource.com/#{id}/declaration_request_Passport.jpeg",
        "PUT" => "http://some_resource.com/#{id}/declaration_request_Passport.jpeg"
      },
      %{
        "type" => "SSN",
        "GET" => "http://some_resource.com/#{id}/declaration_request_SSN.jpeg",
        "PUT" => "http://some_resource.com/#{id}/declaration_request_SSN.jpeg"
      }
    ] == resp["data"]["documents"]
  end
end
