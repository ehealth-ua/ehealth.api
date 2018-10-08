defmodule GraphQLWeb.Resolvers.Person do
  @moduledoc false

  # ToDo: get real persons
  @persons %{
    "1" => %{id: 1, first_name: "John", last_name: "Doe"},
    "2" => %{id: 2, first_name: "Jane", last_name: "Roe"}
  }

  def list_persons(_parent, _args, _resolution) do
    {:ok, Map.values(@persons)}
  end

  def get_person_by(_parent, args, _resolution) do
    {:ok, Map.get(@persons, args.id)}
  end
end
