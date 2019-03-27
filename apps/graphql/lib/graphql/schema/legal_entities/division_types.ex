defmodule GraphQL.Schema.DivisionTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  alias GraphQL.Loaders.PRM

  input_object :division_filter do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:dls_verified, :boolean)
  end

  enum :division_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection node_type: :division do
    field :nodes, list_of(:division) do
      resolve(fn
        _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:division) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:email, non_null(:string))
    field(:mountain_group, non_null(:boolean))
    field(:is_active, non_null(:boolean))
    field(:working_hours, :json)
    # Dictionary: DIVISION_TYPE
    field(:type, non_null(:string))
    # Dictionary: DIVISION_STATUS
    field(:status, non_null(:string))
    field(:dls_verified, :boolean)
    field(:dls_id, :uuid)

    # embed
    field(:phones, non_null(list_of(:phone)))
    field(:addresses, non_null(list_of(:address)), resolve: dataloader(PRM))
  end

  # embed

  # ToDo: map :hours field
  object :division_working_hours do
    #    field(:days, list_of(:week_day))
    #    field(:hours, list_of(:time_range))
  end
end
