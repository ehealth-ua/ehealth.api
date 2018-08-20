defmodule Core.Medications.INNM.Search do
  @moduledoc false

  use Ecto.Schema

  alias Core.Ecto.StringLike

  @primary_key false
  schema "innms_search" do
    field(:id, Ecto.UUID)
    field(:name, StringLike)
    field(:name_original, StringLike)
    field(:sctid, :string)
    field(:is_active, :boolean)
  end
end
