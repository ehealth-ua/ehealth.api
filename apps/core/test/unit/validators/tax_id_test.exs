defmodule Core.Unit.Validators.TaxIDTest do
  @moduledoc false

  use ExUnit.Case

  import Core.Validators.TaxID

  describe "validate/2" do
    test "returns true when tax_id is correct" do
      assert validate("2222222225", nil) == :ok
      assert validate("1111111118", nil) == :ok
    end

    test "returns true when tax_id is not correct" do
      assert validate("", nil) == :error
      assert validate("0000000000", nil) == :error
      assert validate("111111119", nil) == :error
      assert validate("1111111119", nil) == :error
      assert validate("11111111199", nil) == :error
    end
  end
end
