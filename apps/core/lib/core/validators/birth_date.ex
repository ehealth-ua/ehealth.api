defmodule Core.Validators.BirthDate do
  @moduledoc false

  @ages Confex.fetch_env!(:core, Core.Validators.BirthDate)

  def validate(birth_date) do
    birth_date
    |> date_not_in_future()
    |> get_age()
    |> validate_age()
  end

  def date_not_in_future(birth_date) do
    birth_date = Timex.parse!(birth_date, "{YYYY}-{0M}-{D}")

    birth_date
    |> Timex.compare(Timex.now())
    |> case do
      1 -> :error
      _ -> birth_date
    end
  rescue
    _ in ErlangError -> :error
  end

  def get_age(:error), do: :error

  def get_age(date) do
    Timex.diff(Timex.now(), date, :years)
  end

  def validate_age(age) when is_integer(age) do
    age >= @ages[:min_age] and age <= @ages[:max_age]
  end

  def validate_age(_age), do: false
end
