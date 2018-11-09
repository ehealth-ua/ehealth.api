defmodule Core.MedicationRequestRequest.Renderer do
  @moduledoc false

  alias Core.Persons.Renderer, as: PersonsRenderer

  def render_person(%{"birth_date" => birth_date} = person, mrr_created_at) do
    age = get_age(birth_date, mrr_created_at)
    response = PersonsRenderer.render("show.json", person)

    response
    |> Map.put("age", age)
    |> Map.drop(["birth_date", "addresses"])
  end

  defp get_age(birth_date, current_date) do
    Timex.diff(current_date, Timex.parse!(birth_date, "{YYYY}-{0M}-{D}"), :years)
  end
end
