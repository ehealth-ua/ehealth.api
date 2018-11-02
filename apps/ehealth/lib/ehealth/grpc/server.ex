defmodule EHealth.Grpc.Server do
  @moduledoc false

  use GRPC.Server, service: Ehealth.Service

  alias Core.Employees
  alias Core.Employees.Employee
  alias Ecto.UUID
  alias Grpc.EmployeeRequest
  alias Grpc.EmployeeResponse
  alias Grpc.EmployeeResponse.Employee, as: E
  alias Grpc.EmployeeResponse.Speciality

  @spec employee_speciality(EmployeeRequest.t(), GRPC.Server.Stream.t()) :: EmployeeResponse.t()
  def employee_speciality(%EmployeeRequest{id: id}, _stream) do
    with {:ok, _} <- UUID.cast(id),
         %Employee{} = employee <- Employees.get_by_id(id) do
      EmployeeResponse.new(employee: %E{speciality: Speciality.new(speciality: employee.speciality["speciality"])})
    else
      _ ->
        EmployeeResponse.new()
    end
  end
end
