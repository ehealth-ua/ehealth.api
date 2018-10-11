defmodule GraphQLWeb.Resolvers.LegalEntity do
  @moduledoc false

  import Ecto.Query, only: [where: 2, order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo

  @order_by_regex ~r/(\w+)_(asc|desc)$/

  def list_legal_entities(args, _context) do
    LegalEntity
    |> where(^prepare_filter(args))
    |> order_by(^prepare_ordering(args))
    |> Connection.from_query(&PRMRepo.all/1, args)
  end

  def get_legal_entity_by_id(_parent, %{id: id}, _resolution) do
    {:ok, LegalEntities.get_by_id(id)}
  end

  # TODO: move to middleware
  defp prepare_filter(args) do
    args
    |> Map.get(:filter, %{})
    |> Map.to_list()
  end

  # TODO: move to middleware
  defp prepare_ordering(args) do
    with {:ok, order_by} <- Map.fetch(args, :order_by),
         order_by <- Atom.to_string(order_by),
         [field, direction] <- Regex.run(@order_by_regex, order_by, capture: :all_but_first) do
      [{String.to_atom(direction), String.to_atom(field)}]
    else
      _ -> []
    end
  end
end
