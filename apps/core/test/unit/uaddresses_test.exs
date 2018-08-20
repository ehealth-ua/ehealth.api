defmodule Core.Unit.AddressesTest do
  @moduledoc false

  use ExUnit.Case
  alias Core.Divisions.UAddress

  test "check update_required?/2" do
    data = %{"mountain_group" => "yep"}
    settlement = %{"id" => "123", "mountain_group" => "no"}
    assert UAddress.update_required?(data, settlement)
  end
end
