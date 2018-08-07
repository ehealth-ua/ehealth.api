defmodule EHealth.Utils.NumberGeneratorTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.Utils.NumberGenerator, as: Generator

  test "generate(0)" do
    assert "0000-" <> _ = Generator.generate(0)
  end

  test "generate(1)" do
    assert "0001-" <> _ = Generator.generate(1)
  end

  test "generate(0, 2)" do
    number = Generator.generate(0, 2)
    assert "0000-" <> _ = number
    assert 14 == String.length(number)
  end

  test "generate(1, 2)" do
    number = Generator.generate(1, 2)
    assert "0001-" <> _ = number
    assert 14 == String.length(number)
  end

  test "collision" do
    numbers_amount = 1000
    numbers = Enum.map(1..numbers_amount, fn _ -> Generator.generate(1, 2) end)
    assert numbers_amount == length(numbers)
  end
end
