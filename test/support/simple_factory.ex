defmodule EHealth.SimpleFactory do
  @moduledoc false

  alias EHealth.EmployeeRequest.API

  def fixture(:employee_request, email \\ nil), do: employee_request(email)

  def employee_request(email) do
    attrs = "test/data/employee_request.json" |> File.read!() |> Poison.decode!() |> set_email(email)
    {:ok, employee_request} = API.create_employee_request(attrs)
    employee_request
  end

  def set_email(data, nil), do: data
  def set_email(data, email), do: put_in(data, ["employee_request", "party", "email"], email)
end
