defmodule GraphQL.Schema.PhoneTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :phone do
    # Dictionary: PHONE_TYPE
    field(:type, non_null(:string))
    field(:number, non_null(:string))
  end
end
