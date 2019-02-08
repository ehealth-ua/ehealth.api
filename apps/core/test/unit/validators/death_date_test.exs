defmodule Core.Unit.Validators.DeathDateTest do
  @moduledoc false

  use ExUnit.Case
  alias Core.Validators.DeathDate

  test "success for today" do
    today = to_string(Date.utc_today())
    assert :ok == DeathDate.validate(today)
  end

  test "fail for future" do
    assert :error == DeathDate.validate("2200-01-01")
  end

  test "fail for past" do
    assert :error == DeathDate.validate("1800-01-01")
  end

  test "fail for invalid" do
    assert :error == DeathDate.validate("2000-02-31")
  end
end
