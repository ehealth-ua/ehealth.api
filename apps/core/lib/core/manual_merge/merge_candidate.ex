defmodule Core.ManualMerge.MergeCandidate do
  @moduledoc false

  use Ecto.Schema

  alias Core.Persons.Person
  alias Ecto.UUID

  embedded_schema do
    field(:status, :string)
    field(:config, :map)
    field(:details, :map)
    field(:score, :float)

    belongs_to(:person, Person, type: UUID)
    belongs_to(:master_person, Person, type: UUID)

    timestamps(type: :utc_datetime_usec)
  end
end
