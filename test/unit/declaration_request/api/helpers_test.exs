defmodule EHealth.DeclarationRequest.API.HelpersTest do
  @moduledoc false

  use ExUnit.Case, async: true

  import EHealth.DeclarationRequest.API.Helpers

  describe "request_end_date/5" do
    test "patient is less than 18 years old" do
      term       = [years: 40]
      birth_date = "2014-10-10"
      today      = Date.from_iso8601!("2017-10-16")

      assert ~D[2032-10-09] == request_end_date(today, term, birth_date, 18)
    end

    test "patient turns 18 years old tomorrow" do
      term       = [years: 40]
      birth_date = "2000-10-17"
      today      = Date.from_iso8601!("2018-10-16")

      assert ~D[2018-10-16] == request_end_date(today, term, birth_date, 18)
    end

    test "patient turns 18 years today" do
      term       = [years: 40]
      birth_date = "2000-10-17"
      today      = Date.from_iso8601!("2018-10-17")

      assert ~D[2058-10-17] == request_end_date(today, term, birth_date, 18)
    end

    test "patient is older than 18 years" do
      term       = [years: 40]
      birth_date = "1988-10-10"
      today      = Date.from_iso8601!("2017-10-16")

      assert ~D[2057-10-16] == request_end_date(today, term, birth_date, 18)
    end

    test "take min between 18 years and declaration term date" do
      term       = [years: 5]
      birth_date = "1988-10-10"
      today      = Date.from_iso8601!("1990-10-10")

      assert ~D[1995-10-10] == request_end_date(today, term, birth_date, 18)
    end
  end
end
