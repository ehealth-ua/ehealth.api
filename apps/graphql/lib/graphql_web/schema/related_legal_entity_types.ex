defmodule GraphQLWeb.Schema.RelatedLegalEntityTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias GraphQLWeb.Loaders.PRM

  connection(node_type: :related_legal_entity) do
    field :nodes, list_of(:related_legal_entity) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:related_legal_entity) do
    field(:database_id, non_null(:id))
    field(:reason, :string)
    field(:is_active, non_null(:boolean))

    # relations
    field(:merged_to, non_null(:legal_entity), resolve: dataloader(PRM))
    field(:merged_from, non_null(:legal_entity), resolve: dataloader(PRM))

    # dates
    field(:inserted_at, non_null(:string))
    field(:inserted_by, non_null(:string))
  end

  input_object :related_legal_entity_filter do
    field(:is_active, :boolean)
  end

  enum :related_legal_entity_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:is_active_asc)
    value(:is_active_desc)
  end
end
