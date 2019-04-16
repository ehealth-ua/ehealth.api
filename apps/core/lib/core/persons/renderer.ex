defmodule Core.Persons.Renderer do
  @moduledoc false

  def render("show.json", %{} = person) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      addresses
    )a)
  end
end
