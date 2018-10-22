defmodule GraphQLWeb.Resolvers.LegalEntity do
  @moduledoc false

  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Absinthe.Resolution.Helpers, as: ResolutionHelper
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Dataloader.Ecto

  def list_legal_entities(%{filter: filter, order_by: order_by} = args, _context) do
    LegalEntity
    |> where(^filter)
    |> order_by(^order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end

  # dataloader

  def data, do: Ecto.new(PRMRepo, query: &query/2)

  def query(queryable, %{filter: filter, order_by: order_by} = args) do
    {:ok, :forward, limit} = Connection.limit(args)
    limit = limit + 1

    offset =
      case Connection.offset(args) do
        {:ok, offset} when is_integer(offset) -> offset
        _ -> 0
      end

    LegalEntity
    |> where(^filter)
    |> order_by(^order_by)
    |> limit(^limit)
    |> offset(^offset)
  end

  def query(_queryable, _args), do: from(l in LegalEntity)
end
