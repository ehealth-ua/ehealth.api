defmodule GraphQLWeb.Schema.LegalEntityTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias GraphQLWeb.Resolvers.LegalEntity

  object :legal_entity_queries do
    @desc "get list of Legal Entities"
    connection field(:legal_entities, node_type: :legal_entity) do
      meta(:scope, ~w(legal_entity:read))
      arg(:edrpou, :string)
      resolve(&LegalEntity.list_legal_entities/2)
    end

    @desc "get one Legal Entity by id"
    field :legal_entity, :legal_entity do
      meta(:scope, ~w(legal_entity:read))
      arg(:id, non_null(:id))
      resolve(&LegalEntity.get_legal_entity_by_id/3)
    end
  end

  connection(node_type: :legal_entity) do
    field :nodes, list_of(:legal_entity) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  object :legal_entity do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:email, non_null(:string))
    field(:kveds, non_null(list_of(:string)))
    field(:short_name, :string)
    field(:public_name, :string)
    field(:edrpou, non_null(:string))
    field(:owner_property_type, non_null(:string))
    field(:legal_form, non_null(:string))
    field(:website, :string)
    field(:beneficiary, :string)
    field(:nhs_verified, :boolean)

    # enums
    field(:type, non_null(:legal_entity_type))
    field(:status, non_null(:legal_entity_status))
    field(:mis_verified, non_null(:legal_entity_mis_verified))

    # embed
    field(:phones, non_null(list_of(:phone)))
    field(:addresses, non_null(list_of(:address)))
    field(:archive, non_null(list_of(:legal_entity_archive)))
    field(:medical_service_provider, non_null(:msp))

    # dates
    field(:inserted_at, :string)
    field(:updated_at, :string)
  end

  # embed

  object :msp do
    field(:licenses, list_of(:msp_license))
    field(:accreditation, :msp_accreditation)
  end

  object :msp_license do
    field(:license_number, non_null(:string))
    field(:issued_by, non_null(:string))
    field(:issued_date, non_null(:string))
    field(:active_from_date, non_null(:string))
    field(:order_no, non_null(:string))
    field(:expiry_date, :string)
    field(:what_licensed, :string)
  end

  object :msp_accreditation do
    field(:category, non_null(:string))
  end

  object :phone do
    field(:type, :string)
    field(:number, :string)
  end

  object :address do
    field(:type, :string)
    field(:country, :string)
    field(:area, :string)
    field(:region, :string)
    field(:settlement, :string)
    field(:settlement_type, :string)
    field(:settlement_id, :string)
    field(:street, :string)
    field(:street_type, :string)
    field(:building, :string)
    field(:apartment, :string)
    field(:zip, :string)
  end

  object :legal_entity_archive do
    field(:date, :string)
    field(:place, :string)
  end

  # enum

  enum :legal_entity_type do
    value(:mis, as: "MIS")
    value(:msp, as: "MSP")
    value(:pharmacy, as: "PHARMACY")
  end

  enum :legal_entity_status do
    value(:active, as: "ACTIVE")
    value(:closed, as: "CLOSED")
  end

  enum :legal_entity_mis_verified do
    value(:verified, as: "VERIFIED")
    value(:not_verified, as: "NOT_VERIFIED")
  end
end
