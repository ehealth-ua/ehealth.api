defmodule EHealth.MedicationRequestRequest.HumanReadableNumberGeneratorTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.MedicationRequestRequest.HumanReadableNumberGenerator, as: HRNGenerator

  test "generate(1)" do
    assert "0000-" <> _ = HRNGenerator.generate(1)
  end
end
