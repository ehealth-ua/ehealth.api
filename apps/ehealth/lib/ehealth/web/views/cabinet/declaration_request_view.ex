defmodule EHealth.Web.Cabinet.DeclarationRequestView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{declaration_requests: declaration_requests}) do
    render_many(declaration_requests, __MODULE__, "declaration_request_short.json")
  end

  def render("declaration_request_short.json", %{declaration_request: %{data: data} = declaration_request}) do
    declaration_request
    |> Map.take(~w(
      id
      declaration_number
      status
    )a)
    |> Map.put(:start_date, Map.get(data, "start_date"))
    |> Map.put(:person, render_association(:person, Map.get(data, "person", %{})))
    |> Map.put(:employee, render_association(:employee, Map.get(data, "employee", %{})))
    |> Map.put(:legal_entity, render_association(:legal_entity, Map.get(data, "legal_entity", %{})))
    |> Map.put(:division, render_association(:division, Map.get(data, "division", %{})))
  end

  def render_association(_, _, nil), do: nil

  def render_association(:person, data) do
    Map.take(data, ~w(id first_name last_name second_name))
  end

  def render_association(:employee, data) do
    data
    |> Map.take(~w(id position))
    |> Map.put(:party, render_association(:person, Map.get(data, "party")))
  end

  def render_association(:legal_entity, data) do
    Map.take(data, ~w(id name short_name legal_form edrpou))
  end

  def render_association(:division, data) do
    Map.take(data, ~w(id name type status))
  end
end
