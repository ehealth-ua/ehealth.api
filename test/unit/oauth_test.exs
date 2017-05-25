defmodule EHealth.Unit.OAuthAPITest do
  @moduledoc false

  use ExUnit.Case

  alias Ecto.UUID
  alias EHealth.OAuth.API

  test "check client name for client creation" do
    name = "my name"
    client = %{
      "id" => UUID.generate(),
      "name" => name
    }
    assert {:ok, %{"data" => resp}} = API.create_client(client, "example.com", [])
    assert name == resp["name"]
  end
end
