defmodule GraphQLWeb.Schema.MedicationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Medications.Medication
  alias GraphQLWeb.Loaders.PRM
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.MedicationResolver

  object :medication_queries do
    connection field(:medications, node_type: :medication) do
      meta(:scope, ~w(medication:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :medication_filter)
      arg(:order_by, :medication_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        name: :like,
        is_active: :equal,
        form: :equal,
        innm_dosages: [database_id: :equal, name: :like],
        manufacturer: [name: :like]
      )

      resolve(&MedicationResolver.list_medications/2)
    end

    field(:medication, :medication) do
      meta(:scope, ~w(medication:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :medication)

      resolve(load_by_args(PRM, Medication))
    end
  end

  input_object :medication_filter do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:is_active, :boolean)
    field(:form, :string)
    field(:innm_dosages, :innm_dosage_filter)
    field(:manufacturer, :manufacturer_filter)
  end

  input_object :manufacturer_filter do
    field(:name, :string)
  end

  enum :medication_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection node_type: :medication do
    field :nodes, list_of(:medication) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:medication) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:manufacturer, :manufacturer)
    field(:atc_codes, non_null(list_of(:string)), resolve: fn _, res -> {:ok, res.source.code_atc} end)
    field(:form, :medication_form)
    field(:container, non_null(:container))
    field(:package_qty, :integer)
    field(:package_min_qty, :integer)
    field(:certificate, :string)
    field(:certificate_expired_at, :date)
    field(:ingredients, non_null(list_of(:medication_ingredient)), resolve: dataloader(PRM))
    field(:is_active, non_null(:boolean))
    field(:type, :medication_type)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :manufacturer do
    field(:name, non_null(:string))
    field(:country, non_null(:string))
  end

  enum :medication_form do
    value(:aerosol_for_inhalation, as: "AEROSOL_FOR_INHALATION")
    value(:aerosol_for_inhalation_dosed, as: "AEROSOL_FOR_INHALATION_DOSED")
    value(:coated_tablet, as: "COATED_TABLET")
    value(:film_coated_tablet, as: "FILM_COATED_TABLET")
    value(:inhalation_powder, as: "INHALATION_POWDER")
    value(:modifiedrelease_tablet, as: "MODIFIEDRELEASE_TABLET")
    value(:nebuliser_suspension, as: "NEBULISER_SUSPENSION")
    value(:pressurised_inhalation, as: "PRESSURISED_INHALATION")
    value(:sublingval_tablet, as: "SUBLINGVAL_TABLET")
    value(:tablet, as: "TABLET")
  end

  object :container do
    field(:numerator_unit, non_null(:medication_unit))
    field(:numerator_value, non_null(:string))
    field(:denumerator_unit, non_null(:medication_unit))
    field(:denumerator_value, non_null(:string))
  end

  object :medication_ingredient do
    interface(:ingredient)

    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))
    field(:innm_dosage, non_null(:innm_dosage), resolve: dataloader(PRM))
  end

  enum :medication_type do
    value(:brand, as: "BRAND")
    value(:innm_dosage, as: "INNM_DOSAGE")
  end
end
