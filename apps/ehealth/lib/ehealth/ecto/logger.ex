defimpl Ecto.LoggerJSON.StructParser, for: Decimal do
  def parse(value), do: Decimal.to_string(value)
end

defimpl Ecto.LoggerJSON.StructParser, for: Geo.Point do
  def parse(value), do: Geo.JSON.encode(value)
end
