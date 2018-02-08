defmodule EHealth.Registers.SearchRegisterEntries do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "register_entries_search" do
    field(:id, Ecto.UUID)
    field(:register_id, Ecto.UUID)
    field(:tax_id, :string)
    field(:national_id, :string)
    field(:passport, :string)
    field(:birth_certificate, :string)
    field(:temporary_certificate, :string)
    field(:status, :string)
    field(:inserted_at_from, :date)
    field(:inserted_at_to, :date)
  end
end
