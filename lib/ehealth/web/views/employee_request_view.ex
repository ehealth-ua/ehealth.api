defmodule EHealth.Web.EmployeeRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{employee_requests: employee_requests, references: references}) do
    Enum.map(employee_requests, fn request ->
      legal_entity =
        references
        |> Map.get("legal_entities")
        |> Map.get(request.data["legal_entity_id"], %{})
      %{
        id: request.id,
        status: request.status,
        inserted_at: request.inserted_at,
        edrpou: Map.get(legal_entity, :edrpou),
        legal_entity_name: Map.get(legal_entity, :name),
        first_name: get_in(request.data, ["party", "first_name"]),
        second_name: get_in(request.data, ["party", "second_name"]),
        last_name: get_in(request.data, ["party", "last_name"]),
      }
    end)
  end

  def render("show.json", %{employee_request: employee_request, legal_entity: legal_entity}) do
    data = for {key, val} <- employee_request.data, into: %{}, do: {String.to_atom(key), val}
    data
    |> Map.merge(employee_request)
    |> Map.delete(:data)
    |> Map.put(:edrpou, Map.get(legal_entity, :edrpou))
    |> Map.put(:legal_entity_name, Map.get(legal_entity, :name))
    |> Map.put(:first_name, data |> Map.get(:party, %{}) |> Map.get("first_name"))
    |> Map.put(:second_name, data |> Map.get(:party, %{}) |> Map.get("second_name"))
    |> Map.put(:last_name, data |> Map.get(:party, %{}) |> Map.get("last_name"))
  end
end
