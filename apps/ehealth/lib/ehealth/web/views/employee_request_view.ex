defmodule EHealth.Web.EmployeeRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{employee_requests: employee_requests, references: references}) do
    Enum.map(employee_requests, fn request ->
      party = request.data["party"]

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
        first_name: party["first_name"],
        second_name: party["second_name"],
        last_name: party["last_name"],
        no_tax_id: party["no_tax_id"]
      }
    end)
  end

  def render("show.json", %{employee_request: employee_request, legal_entity: legal_entity}) do
    employee_request = Map.from_struct(employee_request)
    data = for {key, val} <- employee_request.data, into: %{}, do: {String.to_atom(key), val}
    party = Map.get(data, :party, %{})

    data
    |> Map.merge(employee_request)
    |> Map.delete(:data)
    |> Map.put(:edrpou, Map.get(legal_entity, :edrpou))
    |> Map.put(:legal_entity_name, Map.get(legal_entity, :name))
    |> Map.put(:first_name, party["first_name"])
    |> Map.put(:second_name, party["second_name"])
    |> Map.put(:last_name, party["last_name"])
    |> Map.put(:no_tax_id, party["no_tax_id"])
    |> Map.drop([:__meta__, :__struct__])
  end
end
