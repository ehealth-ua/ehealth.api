defmodule GraphQLWeb.Schema.PhoneTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :phone do
    field(:type, non_null(:phone_type))
    field(:number, non_null(:string))
  end

  enum :phone_type do
    value(:mobile, as: "MOBILE")
    value(:land_line, as: "LAND_LINE")
  end
end
