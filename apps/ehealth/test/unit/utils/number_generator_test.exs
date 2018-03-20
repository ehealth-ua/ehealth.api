defmodule EHealth.Utils.NumberGeneratorTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.Utils.NumberGenerator, as: Generator

  test "generate(1)" do
    assert "0000-" <> _ = Generator.generate(1)
  end

  test "generate(1, 2)" do
    number = Generator.generate(1, 2)
    assert "0000-" <> _ = number
    assert 14 == String.length(number)
  end
end
