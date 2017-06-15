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

    @tag pending: true
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

      # Must be 07, not 17th, see note in actual code.
      # Result should be "+ 40 years - 10 days" (e.g. loose 1 day every year)
      assert ~D[2058-10-17] == request_end_date(today, term, birth_date, 18)
    end

    test "patient is older than 18 years" do
      term       = [years: 40]
      birth_date = "1988-10-10"
      today      = Date.from_iso8601!("2017-10-16")

      # Must be 06, not 16th, see note in actual code.
      # Result should be "+ 40 years - 10 days" (e.g. loose 1 day every year)
      assert ~D[2057-10-16] == request_end_date(today, term, birth_date, 18)
    end
  end
end
