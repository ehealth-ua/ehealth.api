defmodule EHealth.Unit.LegalEntity.APITest do
  @moduledoc """
  Legal entity api tests
  """

  use EHealth.Web.ConnCase, async: true
  import EHealth.MockServer, only: [get_legal_entity: 3, get_legal_entity: 0]
  alias EHealth.LegalEntity.API

  test "check_status" do
    legal_entity = get_legal_entity(Ecto.UUID.generate, false, "CLOSED")
    assert {:error, {:conflict, _}} = API.check_status(legal_entity)

    legal_entity = get_legal_entity()
    assert :ok == API.check_status(legal_entity)
  end
end
