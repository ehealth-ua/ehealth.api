defmodule EHealth.Unit.AddressesTest do
  @moduledoc false

  use ExUnit.Case
  alias EHealth.Divisions.UAddress

  test "check settlement diff" do
    data = %{"mountain_group" => "yep"}
    settlement = %{"id" => "123", "mountain_group" => "no"}
    pipe_data = %{update_data: data, settlement: %{"data" => settlement}}
    assert {:ok, %{update_data: updated_data}} = UAddress.check_settlement_diff(pipe_data)
    assert data == updated_data
  end
end
