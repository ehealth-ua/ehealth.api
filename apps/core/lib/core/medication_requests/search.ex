defmodule Core.MedicationRequests.Search do
  @moduledoc false

  use Ecto.Schema

  alias Ecto.UUID

  @primary_key false
  schema "medication_requests_search" do
    field(:employee_id, UUID)
    field(:person_id, UUID)
    field(:status, :string)
    field(:request_number, :string)
    field(:created_from, :string)
    field(:created_to, :string)
    field(:medication_id, :string)
    field(:intent, :string)
    field(:page, :integer)
    field(:page_size, :integer)
    field(:legal_entity_id, UUID)
    field(:id, UUID)
  end
end
