defmodule GraphQLWeb.Resolvers.LegalEntity do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo

  def list_legal_entities(%{filter: filter, order_by: order_by} = args, _context) do
    LegalEntity
    |> where(^filter)
    |> order_by(^order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end
end
