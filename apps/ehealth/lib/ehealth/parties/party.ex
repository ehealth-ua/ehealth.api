defmodule EHealth.Parties.Party do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "parties" do
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:gender, :string)
    field(:tax_id, :string)
    field(:no_tax_id, :boolean, default: false)
    field(:educations, {:array, :map})
    field(:qualifications, {:array, :map})
    field(:specialities, {:array, :map})
    field(:science_degree, :map)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)
    field(:declaration_limit, :integer)
    field(:about_myself, :string)
    field(:working_experience, :integer)

    embeds_many(:phones, EHealth.Parties.Phone, on_replace: :delete)
    embeds_many(:documents, EHealth.Parties.Document, on_replace: :delete)

    has_many(:users, EHealth.PartyUsers.PartyUser, foreign_key: :party_id)

    timestamps()
  end
end
