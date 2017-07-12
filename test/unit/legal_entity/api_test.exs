defmodule EHealth.Unit.LegalEntity.APITest do
  @moduledoc """
  Legal entity api tests
  """

  use EHealth.Web.ConnCase, async: true
  import EHealth.MockServer, only: [get_legal_entity: 3, get_legal_entity: 0]
  alias EHealth.LegalEntity.API

  test "check_status" do
    legal_entity = get_legal_entity(Ecto.UUID.generate, false, "CLOSED")
    pipe_data = {:ok, %{legal_entity_prm: %{"data" => [legal_entity]}}}
    assert {:error, {:conflict, _}} = API.check_status(pipe_data)

    legal_entity = get_legal_entity()
    pipe_data = {:ok, %{legal_entity_prm: %{"data" => [legal_entity]}}}
    assert pipe_data == API.check_status(pipe_data)
  end
end
