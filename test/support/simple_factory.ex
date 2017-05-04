defmodule EHealth.SimpleFactory do
  @moduledoc false

  alias EHealth.EmployeeRequest.API

  def fixture(:employee_request), do: employee_request()

  def employee_request do
    attrs = "test/data/employee_request.json" |> File.read!() |> Poison.decode!()
    {:ok, employee_request} = API.create_employee_request(attrs)
    employee_request
  end
end
