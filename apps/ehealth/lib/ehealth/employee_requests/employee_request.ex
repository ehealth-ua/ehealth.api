defmodule EHealth.EmployeeRequests.EmployeeRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_new "NEW"
  @status_approved "APPROVED"
  @status_rejected "REJECTED"
  @status_expired "EXPIRED"

  def status(:new), do: @status_new
  def status(:approved), do: @status_approved
  def status(:rejected), do: @status_rejected
  def status(:expired), do: @status_expired

  schema "employee_requests" do
    field(:data, :map)
    field(:status, :string)
    field(:employee_id, Ecto.UUID)

    timestamps()
  end
end
