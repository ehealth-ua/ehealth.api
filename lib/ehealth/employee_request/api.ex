defmodule EHealth.EmployeeRequest.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  use JValid

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  def create_employee_request(attrs \\ %{}) do
    with :ok <- validate_schema(:employee_request, attrs) do
      Repo.insert(%EmployeeRequest{data: attrs})
    end
  end
end
