defmodule EHealth.Employee.Request do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Poison.Encoder, except: [:__meta__]}

  schema "employee_requests" do
    field :data, :map
    field :status, :string
    field :employee_id, Ecto.UUID

    timestamps()
  end
end
