defmodule EHealth.Registers.RegisterEntry do
  @moduledoc false

  use Ecto.Schema

  @matched "MATCHED"
  @not_found "NOT_FOUND"
  @error "ERROR"
  @processed "PROCESSED"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "register_entries" do
    field(:document_type, :string)
    field(:document_number, :string)
    field(:status, :string)
    field(:inserted_by, Ecto.UUID, null: false)
    field(:updated_by, Ecto.UUID)
    field(:person_id, Ecto.UUID)

    belongs_to(:register, EHealth.Registers.Register, type: Ecto.UUID)

    timestamps()
  end

  def status(:matched), do: @matched
  def status(:not_found), do: @not_found
  def status(:error), do: @error
  def status(:processed), do: @processed
end
