defmodule EHealth.PRM.Parties.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  @fields ~W(
    first_name
    second_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )

  @fields_required ~W(
    first_name
    last_name
    birth_date
    gender
    tax_id
    inserted_by
    updated_by
  )a

  schema "parties" do
    field :first_name, :string
    field :last_name, :string
    field :second_name, :string
    field :birth_date, :date
    field :gender, :string
    field :tax_id, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    embeds_many :phones, EHealth.PRM.Meta.Phone, on_replace: :delete
    embeds_many :documents, EHealth.PRM.Meta.Document, on_replace: :delete

    has_many :users, EHealth.PRM.Parties.PartyUser

    timestamps()
  end

  def fields, do: @fields

  def required, do: @fields_required
end
