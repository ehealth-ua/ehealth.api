defmodule GraphQLWeb.Schema.PersonTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  alias GraphQLWeb.Resolvers.Person

  object :person_queries do
    @desc "Get all persons"
    field :persons, list_of(:person) do
      meta(:scope, ~w(person:list))
      resolve(&Person.list_persons/3)
    end

    @desc "Get person by id"
    field :person, :person do
      arg(:id, non_null(:id))
      meta(:scope, ~w(person:read))
      resolve(&Person.get_person_by/3)
    end
  end

  object :person do
    field(:id, :id)
    field(:first_name, :string)
    field(:last_name, :string)
  end
end
