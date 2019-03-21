defmodule GraphQL.Schema.PartyTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :party_filter do
    field(:full_name, :string)
    field(:no_tax_id, :boolean)
  end

  node object(:party) do
    field(:database_id, non_null(:uuid))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:birth_date, non_null(:string))
    field(:gender, non_null(:gender))
    field(:tax_id, :string)
    field(:no_tax_id, :boolean)
    field(:phones, list_of(:phone))
  end

  enum :gender do
    value(:male, as: "MALE")
    value(:female, as: "FEMALE")
  end
end
