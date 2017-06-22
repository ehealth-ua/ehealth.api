defmodule EHealth.DeclarationRequest.API.Helpers do
  @moduledoc false

  def request_end_date(today, expiration, birth_date, adult_age) do
    birth_date = Date.from_iso8601!(birth_date)

    normal_expiration_date   = Timex.shift(today, expiration)
    adjusted_expiration_date = Timex.shift(birth_date, years: adult_age, days: -1)

    if Timex.diff(today, birth_date, :years) >= adult_age do
      normal_expiration_date
    else
      case Timex.compare(normal_expiration_date, adjusted_expiration_date) do
        -1 -> normal_expiration_date
         0 -> normal_expiration_date
         1 -> adjusted_expiration_date
      end
    end
  end
end
