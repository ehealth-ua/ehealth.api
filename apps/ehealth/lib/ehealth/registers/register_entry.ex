defmodule EHealth.Registers.RegisterEntry do
  @moduledoc false

  use Ecto.Schema

  @matched "MATCHED"
  @not_found "NOT_FOUND"
  @processing "PROCESSING"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "register_entries" do
    field(:tax_id, :string)
    field(:national_id, :string)
    field(:passport, :string)
    field(:birth_certificate, :string)
    field(:temporary_certificate, :string)
    field(:status, :string)
    field(:inserted_by, Ecto.UUID, null: false)
    field(:updated_by, Ecto.UUID)
    field(:person_id, Ecto.UUID)

    belongs_to(:register, EHealth.Registers.Register, type: Ecto.UUID)

    timestamps()
  end

  def status(:matched), do: @matched
  def status(:not_found), do: @not_found
  def status(:processing), do: @processing
end
