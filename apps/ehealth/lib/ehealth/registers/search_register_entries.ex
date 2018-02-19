defmodule EHealth.Registers.SearchRegisterEntries do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "register_entries_search" do
    field(:id, Ecto.UUID)
    field(:register_id, Ecto.UUID)
    field(:person_id, Ecto.UUID)
    field(:document_type, :string)
    field(:document_number, :string)
    field(:status, :string)
    field(:inserted_at_from, :date)
    field(:inserted_at_to, :date)
  end
end
