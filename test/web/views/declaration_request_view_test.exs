defmodule EHealth.Unit.Web.DeclarationRequestView do
  @moduledoc false

  use ExUnit.Case

  import EHealth.Web.DeclarationRequestView

  test "rendering approval response" do
    declaration_request = %{
      id: 1,
      data: "some_data",
      status: "some_status",
      some_other_field: "some_value"
    }

    assert %{
      id: 1,
      data: "some_data",
      status: "some_status"
    } = render("status.json", %{declaration_request: declaration_request})
  end
end
