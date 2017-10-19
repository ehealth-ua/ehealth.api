defmodule EHealth.MedicationRequests.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "medication_requests_search" do
    field :employee_id, Ecto.UUID
    field :person_id, Ecto.UUID
    field :status, :string
    field :request_number, :string
    field :created_at, :string
    field :legal_entity_id, :string
    field :edrpou, :string
    field :page, :integer
    field :page_size, :integer
  end
end
