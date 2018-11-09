defmodule Core.Persons.Renderer do
  @moduledoc false

  alias Core.Persons.Person

  def render("show.json", %Person{} = person) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      addresses
    )a)
  end

  def render("show.json", %{} = person) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
      birth_date
      addresses
    ))
  end
end
