defmodule GraphQLWeb.Schema.ScalarTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input
  alias Core.Ecto.{DateRange, TimestampRange}
  alias Ecto.UUID

  scalar :uuid, name: "UUID" do
    serialize(& &1)
    parse(&do_parse(:uuid, &1))
  end

  scalar :object_id do
    serialize(& &1)
    parse(&do_parse(:object_id, &1))
  end

  scalar :date_interval do
    serialize(&DateRange.to_iso8601/1)
    parse(&do_parse(:date_interval, &1))
  end

  scalar :datetime_interval do
    serialize(&TimestampRange.to_iso8601/1)
    parse(&do_parse(:datetime_interval, &1))
  end

  scalar :json do
    serialize(& &1)
    parse(&do_parse(:json, &1))
  end

  defp do_parse(:uuid, %Input.String{value: value}), do: UUID.cast(value)

  defp do_parse(:object_id, %Input.String{value: value}) do
    case Regex.match?(~r/^[a-f\d]{24}$/i, value) do
      true -> {:ok, value}
      _ -> :error
    end
  end

  defp do_parse(:date_interval, %Input.String{value: value}) do
    case DateRange.from_iso8601(value) do
      {:ok, interval} -> {:ok, interval}
      _ -> :error
    end
  end

  defp do_parse(:datetime_interval, %Input.String{value: value}) do
    case TimestampRange.from_iso8601(value) do
      {:ok, interval} -> {:ok, interval}
      _ -> :error
    end
  end

  defp do_parse(:json, %Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp do_parse(_, %Input.Null{}), do: {:ok, nil}
  defp do_parse(_, _), do: :error
end
