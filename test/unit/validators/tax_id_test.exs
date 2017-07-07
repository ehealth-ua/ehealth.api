defmodule EHealth.Unit.Validators.TaxIDTest do
  @moduledoc false

  use ExUnit.Case

  import EHealth.Validators.TaxID

  describe "validate/1" do
    test "returns true when tax_id is correct" do
      assert validate("2222222225")
      assert validate("1111111118")
    end

    test "returns true when tax_id is not correct" do
      refute validate("")
      refute validate("111111119")
      refute validate("1111111119")
      refute validate("11111111199")
    end
  end
end
