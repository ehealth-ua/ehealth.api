defmodule EHealth.Registers.SearchRegisters do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "registers_search" do
    field(:id, Ecto.UUID)
    field(:file_name, :string)
    field(:type, :string)
    field(:status, :string)
    field(:inserted_at_from, :date)
    field(:inserted_at_to, :date)
  end
end
