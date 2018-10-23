defmodule GraphQLWeb.Resolvers.LegalEntity do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2]
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  alias Absinthe.Relay.Connection
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias GraphQLWeb.Loaders.PRM

  def list_legal_entities(%{filter: filter, order_by: order_by} = args, _context) do
    LegalEntity
    |> where(^filter)
    |> order_by(^order_by)
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end

  def load_divisions(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:divisions, args}, legal_entity)
    |> on_load(fn loader ->
      {:ok, :forward, limit} = Connection.limit(args)

      offset =
        case Connection.offset(args) do
          {:ok, offset} when is_integer(offset) -> offset
          _ -> 0
        end

      records = Dataloader.get(loader, PRM, {:divisions, args}, legal_entity)
      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end)
  end

  def load_employees(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:employees, args}, legal_entity)
    |> on_load(fn loader ->
      {:ok, :forward, limit} = Connection.limit(args)

      offset =
        case Connection.offset(args) do
          {:ok, offset} when is_integer(offset) -> offset
          _ -> 0
        end

      records = Dataloader.get(loader, PRM, {:employees, args}, legal_entity)
      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end)
  end

  def load_related_legal_entities(legal_entity, args, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(PRM, {:merged_from_legal_entities, args}, legal_entity)
    |> on_load(fn loader ->
      {:ok, :forward, limit} = Connection.limit(args)

      offset =
        case Connection.offset(args) do
          {:ok, offset} when is_integer(offset) -> offset
          _ -> 0
        end

      records = Dataloader.get(loader, PRM, {:merged_from_legal_entities, args}, legal_entity)
      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end)
  end
end
