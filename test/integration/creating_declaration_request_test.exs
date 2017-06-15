defmodule EHealth.Integraiton.DeclarationRequestCreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  test "creating declaration request", %{conn: conn} do
    declaration_request_params = File.read!("test/data/declaration_request.json")

    conn =
      conn
      |> put_req_header("x-consumer-id", "0e321b78-5e14-4034-9905-463435391680")
      |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
      |> post("/api/declaration_requests", declaration_request_params)

    resp = json_response(conn, 200)

    id = resp["data"]["id"]

    assert to_string(Date.utc_today) == resp["data"]["data"]["start_date"]
    assert {:ok, _} = Date.from_iso8601(resp["data"]["data"]["end_date"])
    assert "NEW" = resp["data"]["status"]
    assert "0e321b78-5e14-4034-9905-463435391680" = resp["data"]["updated_by"]
    assert "0e321b78-5e14-4034-9905-463435391680" = resp["data"]["inserted_by"]
    assert %{"number" => "+380508887700", "type" => "OTP"} = resp["data"]["authentication_method_current"]
    assert "<html><body>Printout form for declaration request ##{id}</body></hrml>" ==
      resp["data"]["printout_content"]

    assert [
      %{"upload_link" => "http://some_resource.com/declaration-#{id}/Passport.jpeg"},
      %{"upload_link" => "http://some_resource.com/declaration-#{id}/SSN.jpeg"}
    ] == resp["data"]["documents"]
  end
end
