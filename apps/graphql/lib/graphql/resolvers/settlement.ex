defmodule GraphQL.Resolvers.Settlement do
  @moduledoc false

  import GraphQL.Resolvers.Helpers.Load, only: [response_to_ecto_struct: 2]

  alias Absinthe.Relay.Connection
  alias Core.Uaddresses
  alias Core.Uaddresses.Settlement

  def list_settlements(%{filter: filter, order_by: order_by} = args, _) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         {:ok, settlements} <- Uaddresses.list_settlements(filter, order_by, {offset, limit + 1}) do
      opts = [has_previous_page: offset > 0, has_next_page: length(settlements) > limit]
      settlements = Enum.map(settlements, &response_to_ecto_struct(Settlement, &1))

      Connection.from_slice(Enum.take(settlements, limit), offset, opts)
    end
  end
end
