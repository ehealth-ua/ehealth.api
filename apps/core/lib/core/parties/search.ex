defmodule Core.Parties.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:id, Ecto.UUID)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:tax_id, :string)
    field(:no_tax_id, :boolean)
    field(:phone_number, :string)
  end
end
