defmodule GraphQLWeb.Schema.PartyTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :party_filter do
    field(:full_name, :string)
  end

  node object(:party) do
    field(:database_id, non_null(:id))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:birth_date, non_null(:string))
    field(:gender, non_null(:gender))
    field(:phones, list_of(:phone))
  end

  enum :gender do
    value(:male, as: "MALE")
    value(:female, as: "FEMALE")
  end
end
