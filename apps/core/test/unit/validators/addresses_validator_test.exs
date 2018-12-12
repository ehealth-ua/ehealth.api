defmodule Core.Unit.Validators.AddressesTest do
  @moduledoc false

  use ExUnit.Case
  alias Core.Validators.Addresses
  import Core.Expectations.RPC

  describe "validate" do
    test "success validate" do
      expect_uaddresses_validate()
      assert :ok == Addresses.validate([])
    end

    test "validate Requierd type ok" do
      addresses = [
        %{
          "type" => "RESIDENCE"
        }
      ]

      expect_uaddresses_validate()
      assert :ok == Addresses.validate(addresses, "RESIDENCE")
    end

    test "address with type defined few times" do
      addresses = [
        %{
          "type" => "RESIDENCE"
        },
        %{
          "type" => "RESIDENCE"
        }
      ]

      expect_uaddresses_validate()

      assert {:error,
              [
                {%{
                   description: "Single address of type 'RESIDENCE' is required, got: 2",
                   params: [],
                   rule: :invalid
                 }, "$.addresses"}
              ]} == Addresses.validate(addresses, "RESIDENCE")
    end

    test "address without required type RESIDENCE" do
      addresses = []
      expect_uaddresses_validate()

      assert {:error,
              [
                {%{
                   description: "Addresses with type RESIDENCE should be present",
                   params: [],
                   rule: :invalid
                 }, "$.addresses"}
              ]} == Addresses.validate(addresses, "RESIDENCE")
    end
  end
end
