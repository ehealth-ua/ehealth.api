defmodule Core.Unit.OAuthAPITest do
  @moduledoc false

  use ExUnit.Case

  import Core.Expectations.Mithril
  alias Ecto.UUID
  alias Core.OAuth.API
  alias Core.LegalEntities.LegalEntity

  test "check client name for client creation" do
    put_client()
    name = "my name"

    client = %LegalEntity{
      id: UUID.generate(),
      name: name
    }

    assert {:ok, %{"data" => resp}} = API.put_client(client, "example.com", Ecto.UUID.generate(), [])
    assert name == resp["name"]
  end
end
