defmodule Ecto.LoggerJSON do
  @moduledoc """
  Keep in sync with https://github.com/elixir-ecto/ecto/blob/master/lib/ecto/log_entry.ex
  Struct used for logging entries.
  It is composed of the following fields:
    * query - the query as string or a function that when invoked resolves to string;
    * source - the query data source;
    * params - the query parameters;
    * result - the query result as an `:ok` or `:error` tuple;
    * query_time - the time spent executing the query in native units;
    * decode_time - the time spent decoding the result in native units (it may be nil);
    * queue_time - the time spent to check the connection out in native units (it may be nil);
    * connection_pid - the connection process that executed the query;
    * ansi_color - the color that chould be used when logging the entry.
  Notice all times are stored in native unit. You must convert them to
  the proper unit by using `System.convert_time_unit/3` before logging.
  """

  require Logger

  @doc """
  Overwritten to use JSON
  Logs the given entry in debug mode.
  The logger call will be removed at compile time if
  `compile_time_purge_level` is set to higher than debug.
  """
  @spec log(%{}) :: %{}
  def log(entry) do
    _ =
      Logger.debug(fn ->
        %{query_time: query_time, decode_time: decode_time, queue_time: queue_time, query: query, params: params} =
          entry

        [query_time, decode_time, queue_time] =
          [query_time, decode_time, queue_time]
          |> Enum.map(&format_time/1)

        %{
          "decode_time" => decode_time,
          "duration" => Float.round(query_time + decode_time + queue_time, 3),
          "log_type" => "persistence",
          "request_id" => Logger.metadata()[:request_id],
          "query" => query,
          "query_time" => query_time,
          "queue_time" => queue_time,
          "params" => Enum.map(params, &param_to_string/1)
        }
        |> Poison.encode!()
      end)

    entry
  end

  @doc """
  Overwritten to use JSON
  Logs the given entry in the given level.
  The logger call won't be removed at compile time as
  custom level is given.
  """
  @spec log(%{}, atom) :: %{}
  def log(entry, level) do
    _ =
      Logger.log(level, fn ->
        %{query_time: query_time, decode_time: decode_time, queue_time: queue_time, query: query, params: params} =
          entry

        [query_time, decode_time, queue_time] =
          [query_time, decode_time, queue_time]
          |> Enum.map(&format_time/1)

        %{
          "decode_time" => decode_time,
          "duration" => Float.round(query_time + decode_time + queue_time, 3),
          "log_type" => "persistence",
          "request_id" => Logger.metadata()[:request_id],
          "query" => query,
          "query_time" => query_time,
          "queue_time" => queue_time,
          "params" => Enum.map(params, &param_to_string/1)
        }
        |> Poison.encode!()
      end)

    entry
  end

  defp param_to_string({{_, _, _} = date, {h, m, s, _}}) do
    Ecto.DateTime.from_erl({date, {h, m, s}})
  end

  defp param_to_string({_, _, _} = date) do
    Date.from_erl!(date)
  end

  defp param_to_string(%Geo.Point{} = value), do: Geo.JSON.encode(value)
  defp param_to_string(%Decimal{} = value), do: Decimal.to_string(value)

  defp param_to_string(value) when is_list(value) or is_map(value) do
    Enum.map(value, &param_to_string/1)
  end

  defp param_to_string(value) do
    if String.valid?(value) do
      value
    else
      case Ecto.UUID.load(value) do
        {:ok, uuid} -> uuid
        _ -> inspect(value)
      end
    end
  end

  defp format_time(nil), do: 0.0

  defp format_time(time) do
    ms = System.convert_time_unit(time, :native, :micro_seconds) / 1000
    Float.round(ms, 3)
  end
end
