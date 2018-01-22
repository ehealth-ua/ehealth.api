defmodule EHealth.Unit.MithrilAPITest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.API.Mithril

  @consumer_id "78a7ea0a-29e7-4e5f-80d4-b9eec4fec994"

  test "create client" do
    id = "8c30e521-e1f8-42b2-a596-63f257b2a647"

    redirect_uri = "http://example.com/redirect"

    client_data = %{
      "id" => id,
      "name" => "test-legal-entity-" <> id,
      "redirect_uri" => redirect_uri,
      "user_id" => @consumer_id
    }

    assert {:ok, %{"data" => %{}}} = Mithril.put_client(client_data, get_headers())
  end

  def get_headers do
    [
      {"content-type", "application/json"},
      {"x-consumer-id", @consumer_id}
    ]
  end
end
