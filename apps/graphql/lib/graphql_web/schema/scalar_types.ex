defmodule GraphQLWeb.Schema.ScalarTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

  scalar :date_interval do
    serialize(&serialize_date_interval/1)
    parse(&parse_date_interval/1)
  end

  defp serialize_date_interval(%{first: first, last: last}) do
    with {:ok, first} <- serialize_date_interval_boundary(first),
         {:ok, last} <- serialize_date_interval_boundary(last) do
      {:ok, "#{first}/#{last}"}
    else
      _ -> :error
    end
  end

  defp serialize_date_interval_boundary(nil), do: {:ok, ".."}
  defp serialize_date_interval_boundary(date), do: Date.to_iso8601(date)

  defp parse_date_interval(%Input.String{value: value}) do
    with {:ok, first, last} <- raw_from_date_interval(value),
         {:ok, first} <- parse_date_interval_boundary(first),
         {:ok, last} <- parse_date_interval_boundary(last) do
      {:ok, %{first: first, last: last}}
    else
      _ -> :error
    end
  end

  defp parse_date_interval(%Input.Null{}), do: {:ok, nil}
  defp parse_date_interval(_), do: :error

  defp raw_from_date_interval(<<first::binary-size(10), ?/, last::binary-size(10)>>), do: {:ok, first, last}
  defp raw_from_date_interval(<<first::binary-size(10), ?/, ?., ?.>>), do: {:ok, first, nil}
  defp raw_from_date_interval(<<?., ?., ?/, last::binary-size(10)>>), do: {:ok, nil, last}
  defp raw_from_date_interval(_), do: {:error, :invalid_format}

  defp parse_date_interval_boundary(nil), do: {:ok, nil}
  defp parse_date_interval_boundary(date), do: Date.from_iso8601(date)
end
