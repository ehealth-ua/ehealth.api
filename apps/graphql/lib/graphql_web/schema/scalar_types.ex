defmodule GraphQLWeb.Schema.ScalarTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input
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
    serialize(&Date.Interval.to_edtf/1)
    parse(&do_parse(:date_interval, &1))
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
    case Date.Interval.from_edtf(value) do
      {:ok, interval} -> {:ok, interval}
      _error -> :error
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
