defmodule EHealth.MedicationDispenses.SearchByMedicationRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_dispenses_search_by_medication_request" do
    field(:medication_request_id, Ecto.UUID)
    field(:legal_entity_id, Ecto.UUID)
    field(:status, :string)
    field(:page, :integer)
    field(:page_size, :integer)
  end
end
