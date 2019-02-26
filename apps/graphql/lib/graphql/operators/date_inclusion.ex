defmodule GraphQL.Operators.DateInclusion do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      def apply(query, {field, :in, %Date.Interval{first: %Date{} = first, last: %Date{} = last}}, :date, _) do
        where(
          query,
          [..., r],
          fragment("? <@ daterange(?, ?, '[]')", field(r, ^field), ^first, ^last)
        )
      end

      def apply(query, {field, :in, %Date.Interval{first: %Date{} = first}}, :date, _) do
        where(
          query,
          [..., r],
          fragment("? <@ daterange(?, 'infinity', '[)')", field(r, ^field), ^first)
        )
      end

      def apply(query, {field, :in, %Date.Interval{last: %Date{} = last}}, :date, _) do
        where(
          query,
          [..., r],
          fragment("? <@ daterange('infinity', ?, '(]')", field(r, ^field), ^last)
        )
      end
    end
  end
end
