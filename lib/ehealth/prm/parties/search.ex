defmodule EHealth.PRM.Parties.Search do
  @moduledoc false

  use Ecto.Schema

  schema "party_search" do
    field :first_name, :string
    field :last_name, :string
    field :second_name, :string
    field :birth_date, :date
    field :tax_id, :string
    field :phone_number, :string
  end
end
