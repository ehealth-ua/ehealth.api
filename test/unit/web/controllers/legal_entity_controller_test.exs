defmodule EHealth.Web.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  test "create legal entity", %{conn: conn} do
    legal_entity_params = %{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => File.read!("test/data/signed_content.txt"),
    }

    conn = put conn, legal_entity_path(conn, :create_or_update), legal_entity_params
    assert json_response(conn, 200)["data"]
  end

  test "invalid legal entity", %{conn: conn} do
    conn = put conn, legal_entity_path(conn, :create_or_update), %{"invlid" => "data"}
    resp = json_response(conn, 422)
    assert Map.has_key?(resp, "error")
    assert resp["error"]
  end
end
