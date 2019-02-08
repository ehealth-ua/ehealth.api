defmodule Core.Validators.DeathDate do
  @moduledoc false

  def validate(death_date) when is_binary(death_date) do
    with {:ok, date} <- Date.from_iso8601(death_date),
         true <- date in Date.range(valid_from_date(), Date.utc_today()) do
      :ok
    else
      _ -> :error
    end
  end

  defp valid_from_date, do: ~D[1900-01-01]
end
