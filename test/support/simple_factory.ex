defmodule EHealth.SimpleFactory do
  @moduledoc false

  alias EHealth.Repo
  alias EHealth.Employee.Request

  def fixture(:employee_request, email \\ nil, status \\ nil), do: employee_request(email, status)

  def employee_request(email, status) do
    attrs =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> set_email(email)
      |> set_status(status)

    data = Map.fetch!(attrs, "employee_request")
    request = %Request{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")}
    {:ok, employee_request} = Repo.insert(request)

    employee_request
  end

  def set_status(data, nil), do: data
  def set_status(data, status) do
    put_in(data, ["employee_request", "status"], status)
  end

  def set_email(data, nil), do: data
  def set_email(data, email), do: put_in(data, ["employee_request", "party", "email"], email)
end
