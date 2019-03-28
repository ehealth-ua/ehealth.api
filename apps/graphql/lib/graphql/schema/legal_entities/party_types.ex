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
    # Dictionary: GENDER
    field(:gender, non_null(:string))
    field(:tax_id, non_null(:string))
    field(:no_tax_id, :boolean)
    field(:email, non_null(:phone))
    field(:phones, list_of(non_null(:phone)))
    field(:documents, list_of(non_null(:party_document)))
    field(:about_myself, :string)
    field(:working_experience, :integer)
  end

  object :party_document do
    field(:type, non_null(:string))
    field(:number, non_null(:string))
    field(:issued_by, :string)
    field(:issued_at, :date)
  end
end
