defmodule EHealth.Web.EmployeeRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.EmployeeRequestView

  def render("index.json", %{employee_requests: employee_requests}) do
    render_many(employee_requests, EmployeeRequestView, "employee_request_short.json")
  end

  def render("show.json", %{employee_request: employee_request}) do
    render_one(employee_request, EmployeeRequestView, "employee_request_full.json")
  end

  def render("employee_request_full.json", %{employee_request: employee_request}) do
    data = for {key, val} <- employee_request.data, into: %{}, do: {String.to_atom(key), val}
    data
    |> Map.merge(employee_request)
    |> Map.delete(:data)
    |> Map.put(:edrpou, data |> Map.get(:legal_entity, %{}) |> Map.get(:edrpou))
    |> Map.put(:legal_entity_name, data |> Map.get(:legal_entity, %{}) |> Map.get(:name))
    |> Map.put(:first_name, data |> Map.get("party", %{}) |> Map.get("first_name"))
    |> Map.put(:second_name, data |> Map.get("party", %{}) |> Map.get("second_name"))
    |> Map.put(:last_name, data |> Map.get("party", %{}) |> Map.get("last_name"))
    |> Map.delete(:legal_entity)
  end

  def render("employee_request_short.json", %{employee_request: employee_request}) do
    %{
      id: Map.get(employee_request, :id),
      status: Map.get(employee_request, :status),
      inserted_at: Map.get(employee_request, :inserted_at),
      edrpou: employee_request |> Map.get(:legal_entity, %{}) |> Map.get(:edrpou),
      legal_entity_name: employee_request |> Map.get(:legal_entity, %{}) |> Map.get(:name),
      first_name: get_in(employee_request.data, ["party", "first_name"]),
      second_name: get_in(employee_request.data, ["party", "second_name"]),
      last_name: get_in(employee_request.data, ["party", "last_name"]),
    }
  end
end
