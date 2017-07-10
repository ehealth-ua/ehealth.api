defmodule EHealth.SimpleFactory do
  @moduledoc false

  alias EHealth.Repo
  alias EHealth.Employee.Request
  alias EHealth.DeclarationRequest

  defmacro fixture(module) do
    quote do
      module = unquote module
      case module do
        Request -> employee_request()
        DeclarationRequest -> declaration_request()
      end
    end
  end

  defmacro fixture(module, params) do
    quote do
      module = unquote module
      params = unquote params
      case module do
        Request ->
          employee_request(
            Map.get(params, :email),
            Map.get(params, :status),
            Map.get(params, :employee_type)
          )
        _ ->
          module
          |> struct(params)
          |> Repo.insert!
      end
    end
  end

  def employee_request(email \\ nil, status \\ nil, employee_type \\ nil) do
    attrs =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["employee_request", "legal_entity_id"], "8b797c23-ba47-45f2-bc0f-521013e01074")
      |> set_email(email)
      |> set_status(status)
      |> set_employee_type(employee_type)

    data = Map.fetch!(attrs, "employee_request")
    request = %Request{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")}
    {:ok, employee_request} = Repo.insert(request)

    employee_request
  end

  def declaration_request do
    uuid = Ecto.UUID.generate
    %DeclarationRequest{
      data: %{},
      status: "",
      inserted_by: uuid,
      updated_by: uuid,
      authentication_method_current: %{},
      printout_content: "",
    }
    |> Repo.insert!()
  end

  def set_status(data, nil), do: data
  def set_status(data, status) do
    put_in(data, ["employee_request", "status"], status)
  end

  def set_employee_type(data, nil), do: data
  def set_employee_type(data, employee_type) do
    Map.put(data, "employee_type", employee_type)
  end

  def set_email(data, nil), do: data
  def set_email(data, email), do: put_in(data, ["employee_request", "party", "email"], email)
end
