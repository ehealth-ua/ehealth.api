defmodule GraphQLWeb.Resolvers.LegalEntity do
  @moduledoc false

  import Ecto.Query, only: [where: 3]

  alias Absinthe.Relay.Connection
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo

  @filters ~w(edrpou)a

  def list_legal_entities(args, _context) do
    LegalEntity
    |> prepare_where(args)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end

  defp prepare_where(query, args) do
    where =
      args
      |> Map.take(@filters)
      |> Enum.into([])

    where(query, [], ^where)
  end
end
