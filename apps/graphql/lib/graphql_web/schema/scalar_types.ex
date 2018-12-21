defmodule GraphQLWeb.Schema.ScalarTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

  scalar :date_interval do
    serialize(&Date.Interval.to_edtf/1)
    parse(&parse_date_interval/1)
  end

  scalar :json do
    serialize(& &1)
    parse(&decode_json/1)
  end

  defp parse_date_interval(%Input.String{value: value}) do
    case Date.Interval.from_edtf(value) do
      {:ok, interval} -> {:ok, interval}
      _error -> :error
    end
  end

  defp parse_date_interval(%Input.Null{}), do: {:ok, nil}
  defp parse_date_interval(_), do: :error

  defp decode_json(%Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode_json(%Input.Null{}), do: {:ok, nil}
  defp decode_json(_), do: :error
end
