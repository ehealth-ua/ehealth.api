defmodule EHealth.MedicationDispenses.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:id, Ecto.UUID)
    field(:medication_request_id, Ecto.UUID)
    field(:legal_entity_id, Ecto.UUID)
    field(:division_id, Ecto.UUID)
    field(:status, :string)
    field(:dispensed_from, :date)
    field(:dispensed_to, :date)
    field(:page, :integer)
    field(:page_size, :integer)
    field(:dispensed_by, :string)
  end
end
