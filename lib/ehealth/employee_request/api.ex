defmodule EHealth.EmployeeRequest.API do
  @moduledoc false

  use JValid

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  alias EHealth.EmployeeRequest.EmployeeCreator

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def create_employee_request(attrs \\ %{}) do
    with :ok <- validate_schema(:employee_request, attrs) do
      data = Map.fetch!(attrs, "employee_request")
      Repo.insert(%EmployeeRequest{data: data, status: Map.fetch!(data, "status")})
    end
  end

  def reject_employee_request(id) do
    update_status(id, @status_rejected)
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_by_id!(id)

    employee_request
    |> EmployeeCreator.create(req_headers)
    |> update_status(employee_request, @status_approved)
  end

  def update_status(id, status) when is_binary(id) do
    id
    |> get_by_id!()
    |> changeset(%{status: status})
    |> Repo.update()
  end

  def update_status({:ok, _}, %EmployeeRequest{} = employee_request, status) do
    employee_request
    |> changeset(%{status: status})
    |> Repo.update()
  end

  def update_status(err, _employee_request, _status), do: err

  def changeset(%EmployeeRequest{} = schema, attrs) do
    fields = ~W(
      data
      status
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def get_by_id!(id) do
    Repo.get!(EmployeeRequest, id)
  end
end
