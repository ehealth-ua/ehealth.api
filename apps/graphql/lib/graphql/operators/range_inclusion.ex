defmodule GraphQL.Operators.RangeInclusion do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      alias Core.Ecto.{DateRange, TimestampRange}

      @timestamp_types [:naive_datetime, :utc_datetime, :utc_datetime_usec]

      def apply(query, {field, :in, %DateRange{} = value}, :date, _) do
        where(
          query,
          [..., r],
          fragment("? <@ ?", field(r, ^field), type(^value, DateRange))
        )
      end

      def apply(query, {field, :in, %TimestampRange{} = value}, type, _) when type in @timestamp_types do
        where(
          query,
          [..., r],
          fragment("? <@ ?", field(r, ^field), type(^value, TimestampRange))
        )
      end
    end
  end
end
