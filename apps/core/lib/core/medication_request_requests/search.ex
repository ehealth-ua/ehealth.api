defmodule Core.MedicationRequestRequest.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_requests_request_search" do
    field(:employee_id, Ecto.UUID)
    field(:person_id, Ecto.UUID)
    field(:status, :string)
    field(:intent, :string)
    field(:page, :integer)
    field(:page_size, :integer)
  end
end
