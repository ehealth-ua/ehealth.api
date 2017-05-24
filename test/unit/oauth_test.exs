defmodule EHealth.Unit.OAuthAPITest do
  @moduledoc false

  use ExUnit.Case

  alias Ecto.UUID
  alias EHealth.OAuth.API

  test "check client name for client creation" do
    short_name = "my name"
    client = %{
      "id" => UUID.generate(),
      "short_name" => short_name
    }
    assert {:ok, %{"data" => resp}} = API.create_client(client, "example.com", [])
    assert short_name == resp["name"]
  end
end
