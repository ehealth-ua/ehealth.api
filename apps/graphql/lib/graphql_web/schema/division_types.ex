defmodule GraphQLWeb.Schema.DivisionTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Core.Divisions.Division
  alias GraphQLWeb.Loaders.PRM

  @active Division.status(:active)
  @inactive Division.status(:inactive)

  @type_clinic Division.type(:clinic)
  @type_ambulant_clinic Division.type(:ambulant_clinic)
  @type_fap Division.type(:fap)
  @type_drugstore Division.type(:drugstore)
  @type_drugstore_point Division.type(:drugstore_point)

  connection node_type: :division do
    field :nodes, list_of(:division) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  node object(:division) do
    field(:database_id, non_null(:id))
    field(:name, non_null(:string))
    field(:email, non_null(:string))
    field(:employee_type, non_null(:string))
    field(:mountain_group, non_null(:boolean))
    field(:is_active, non_null(:boolean))
    field(:working_hours, :json)

    # enums
    field(:type, non_null(:division_type))
    field(:status, non_null(:division_status))

    # embed

    field(:phones, non_null(list_of(:phone)))
    field(:addresses, non_null(list_of(:address)), resolve: dataloader(PRM))
  end

  input_object :division_filter do
    field(:name, :string)
    field(:is_active, :boolean)
  end

  enum :division_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  # enum

  enum :division_status do
    value(:active, as: @active)
    value(:inactive, as: @inactive)
  end

  enum :division_type do
    value(:clinit, as: @type_clinic)
    value(:ambulant_clinic, as: @type_ambulant_clinic)
    value(:fap, as: @type_fap)
    value(:drugstore, as: @type_drugstore)
    value(:drugstore_point, as: @type_drugstore_point)
  end

  # embed
  # ToDo: map :hours field
  object :division_working_hours do
    #    field(:days, list_of(:week_day))
    #    field(:hours, list_of(:time_range))
  end
end
