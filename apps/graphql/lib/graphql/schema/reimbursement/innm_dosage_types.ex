defmodule GraphQL.Schema.INNMDosageTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Medications.INNMDosage
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.{Filtering, OrderByArgument}
  alias GraphQL.Resolvers.INNMDosage, as: INNMDosageResolver

  object :innm_dosage_queries do
    connection field(:innm_dosages, node_type: :innm_dosage) do
      meta(:scope, ~w(innm_dosage:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :innm_dosage_filter)
      arg(:order_by, :innm_dosage_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        name: :like,
        is_active: :equal,
        form: :equal,
        ingredients: [
          is_primary: :equal,
          innm: [
            database_id: :equal,
            name: :like,
            is_active: :equal,
            name_original: :like,
            sctid: :equal
          ]
        ]
      )

      middleware(OrderByArgument, order_by_arg: :order_by)

      resolve(&INNMDosageResolver.list_innm_dosages/2)
    end

    field :innm_dosage, :innm_dosage do
      meta(:scope, ~w(innm_dosage:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :innm_dosage)

      resolve(load_by_args(PRM, INNMDosage))
    end
  end

  object :innm_dosage_connection, name: "INNMDosageConnection" do
    field(:page_info, type: non_null(:page_info))
    field(:edges, type: list_of(:innm_dosage_edge))

    field :nodes, list_of(:innm_dosage) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end
  end

  object :innm_dosage_edge, name: "INNMDosageEdge" do
    field(:node, :innm_dosage)
    field(:cursor, non_null(:string))
  end

  input_object :innm_dosage_filter, name: "INNMDosageFilter" do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:is_active, :boolean)
    field(:form, :medication_form)
    field(:ingredients, :innm_dosage_ingredient_filter)
  end

  input_object :innm_dosage_ingredient_filter, name: "INNMDosageIngredientFilter" do
    field(:is_primary, :boolean)
    field(:innm, :innm_filter)
  end

  enum :innm_dosage_order_by, name: "INNMDosageOrderBy" do
    value(:form_asc)
    value(:form_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  object :innm_dosage_mutations do
    field(:create_innm_dosage, :create_innm_dosage_payload) do
      meta(:scope, ~w(innm_dosage:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:input, :create_innm_dosage_input)

      middleware(Absinthe.Relay.Mutation)
      middleware(ParseIDs, ingredients: [innm_id: :innm])

      resolve(&INNMDosageResolver.create/2)
    end

    field(:deactivate_innm_dosage, :deactivate_innm_dosage_payload) do
      meta(:scope, ~w(innm_dosage:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:input, :deactivate_innm_dosage_input)

      middleware(Absinthe.Relay.Mutation)
      middleware(ParseIDs, id: :innm_dosage)

      resolve(&INNMDosageResolver.deactivate/2)
    end
  end

  input_object :create_innm_dosage_input, name: "CreateINNMDosageInput" do
    field(:name, non_null(:string))
    field(:form, non_null(:medication_form))
    field(:ingredients, non_null(list_of(:create_innm_dosage_ingredient_input)))
  end

  input_object :create_innm_dosage_ingredient_input, name: "CreateINNMDosageIngredientInput" do
    field(:dosage, non_null(:create_dosage_input))
    field(:is_primary, non_null(:boolean))
    field(:innm_id, non_null(:id))
  end

  object :create_innm_dosage_payload, name: "CreateINNMDosagePayload" do
    field(:innm_dosage, :innm_dosage)
  end

  input_object :deactivate_innm_dosage_input, name: "DeactivateINNMDosageInput" do
    field(:id, non_null(:id))
  end

  object :deactivate_innm_dosage_payload, name: "DeactivateINNMDosagePayload" do
    field(:innm_dosage, :innm_dosage)
  end

  node object(:innm_dosage, name: "INNMDosage") do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:form, non_null(:medication_form))
    field(:ingredients, non_null(list_of(:innm_dosage_ingredient)), resolve: dataloader(PRM))
    field(:is_active, non_null(:boolean))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object(:innm_dosage_ingredient, name: "INNMDosageIngredient") do
    interface(:ingredient)

    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))
    field(:innm, non_null(:innm), resolve: dataloader(PRM))
  end
end
