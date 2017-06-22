defmodule EHealth.DeclarationRequest.API.Helpers do
  @moduledoc false

  def request_end_date(today, expiration, birth_date, adult_age) do
    birth_date = Date.from_iso8601!(birth_date)

    if Timex.diff(today, birth_date, :years) >= adult_age do
      Timex.shift(today, expiration)
    else
      Timex.shift(birth_date, years: adult_age, days: -1)
    end
  end
end
