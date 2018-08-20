defmodule Core.Unit.Validators.AddressesTest do
  @moduledoc false

  use ExUnit.Case
  alias Core.Validators.Addresses
  import Mox

  describe "validate" do
    test "success validate" do
      expect(UAddressesMock, :validate_addresses, fn _, _ ->
        {:ok, %{"data" => %{}}}
      end)

      assert :ok == Addresses.validate([], [])
    end
  end
end
