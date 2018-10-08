defmodule GraphQLWeb.Schema.EmployeeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias GraphQLWeb.Resolvers.Employee

  object :employee do
    field(:id, non_null(:id))
    field(:position, non_null(:string))
    field(:start_date, non_null(:string))
    field(:end_date, :string)
    field(:employee_type, non_null(:string))

    # enums
    field(:status, non_null(:employee_status))
  end

  # enum

  enum :employee_status do
    value(:new, as: "NEW")
    value(:approved, as: "APPROVED")
    value(:dismissed, as: "DISMISSED")
  end
end
