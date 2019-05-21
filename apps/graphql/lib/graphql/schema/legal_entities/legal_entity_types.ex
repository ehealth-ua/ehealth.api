defmodule GraphQL.Schema.LegalEntityTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.LegalEntity, as: LegalEntityResolver

  object :legal_entity_queries do
    @desc "get list of Legal Entities"
    connection field(:legal_entities, node_type: :legal_entity) do
      meta(:scope, ~w(legal_entity:read))

      arg(:filter, :legal_entity_filter)
      arg(:order_by, :legal_entity_order_by, default_value: :inserted_at_desc)

      middleware(ParseIDs, filter: [addresses: [settlement_id: :settlement]])

      middleware(Filtering,
        database_id: :equal,
        type: :in,
        status: :equal,
        edrpou: :like,
        name: :like,
        nhs_verified: :equal,
        nhs_reviewed: :equal,
        edr_verified: :equal,
        addresses: [
          type: :equal,
          settlement_id: :equal
        ]
      )

      resolve(&LegalEntityResolver.list_legal_entities/2)
    end

    @desc "get one Legal Entity by id"
    field :legal_entity, :legal_entity do
      meta(:scope, ~w(legal_entity:read))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityResolver.get_legal_entity_by_id/3)
    end
  end

  input_object :legal_entity_filter do
    field(:database_id, :uuid)
    # Dictionary: LEGAL_ENTITY_TYPE
    field(:type, list_of(:string))
    field(:status, :legal_entity_status)
    field(:edrpou, :string)
    field(:name, :string)
    field(:nhs_verified, :boolean)
    field(:nhs_reviewed, :boolean)
    field(:edr_verified, :boolean)
    field(:addresses, :address_filter)
  end

  enum :legal_entity_order_by do
    value(:edrpou_asc)
    value(:edrpou_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:nhs_reviewed_asc)
    value(:nhs_reviewed_desc)
    value(:nhs_verified_asc)
    value(:nhs_verified_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection(node_type: :legal_entity) do
    field :nodes, list_of(:legal_entity) do
      resolve(fn _, %{source: conn} ->
        nodes = conn.edges |> Enum.map(& &1.node)
        {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  object :legal_entity_mutations do
    payload field(:nhs_verify_legal_entity) do
      meta(:scope, ~w(legal_entity:nhs_verify))
      meta(:client_metadata, ~w(client_id)a)

      input do
        field(:id, non_null(:id))
        field(:nhs_verified, non_null(:boolean))
      end

      output do
        field(:legal_entity, :legal_entity)
      end

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityResolver.nhs_verify/2)
    end

    payload field(:nhs_review_legal_entity) do
      meta(:scope, ~w(legal_entity:nhs_verify))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:legal_entity, :legal_entity)
      end

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityResolver.nhs_review/2)
    end

    payload field(:nhs_comment_legal_entity) do
      meta(:scope, ~w(legal_entity:nhs_verify))

      input do
        field(:id, non_null(:id))
        field(:nhs_comment, non_null(:string))
      end

      output do
        field(:legal_entity, :legal_entity)
      end

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityResolver.nhs_comment/2)
    end

    payload field(:update_legal_entity_status) do
      meta(:scope, ~w(legal_entity:update))

      input do
        field(:id, non_null(:id))
        field(:status, non_null(:legal_entity_updateable_status))
        field(:reason, non_null(:string))
      end

      output do
        field(:legal_entity, :legal_entity)
      end

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityResolver.update_status/2)
    end
  end

  enum :legal_entity_updateable_status do
    value(:active, as: "ACTIVE")
    value(:suspended, as: "SUSPENDED")
  end

  node object(:legal_entity) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:email, non_null(:string))
    field(:kveds, non_null(list_of(:string)))
    field(:short_name, :string)
    field(:public_name, :string)
    field(:edrpou, non_null(:string))
    field(:owner_property_type, non_null(:string))
    field(:legal_form, non_null(:string))
    field(:status_reason, :string)
    field(:reason, :string)
    field(:website, :string)
    field(:receiver_funds_code, :string)
    field(:beneficiary, :string)
    field(:nhs_verified, :boolean)
    field(:nhs_unverified_at, :datetime)
    field(:nhs_reviewed, :boolean)
    field(:nhs_comment, :string)
    field(:edr_verified, :boolean)
    field(:accreditation, :accreditation)

    # enums

    # Dictionary: LEGAL_ENTITY_TYPE
    field(:type, non_null(:string))
    field(:status, non_null(:legal_entity_status))
    field(:mis_verified, non_null(:legal_entity_mis_verified))

    # embed
    field(:phones, non_null(list_of(:phone)))
    field(:addresses, non_null(list_of(:address)))
    field(:archive, list_of(:legal_entity_archive))
    field(:license, :license, resolve: dataloader(PRM))

    # relations
    field(:owner, :employee, resolve: &LegalEntityResolver.load_owner/3)

    connection field(:employees, node_type: :employee) do
      arg(:filter, :employee_filter)
      arg(:order_by, :employee_order_by, default_value: :inserted_at_asc)

      middleware(Filtering,
        database_id: :equal,
        employee_type: :in,
        status: :equal,
        is_active: :equal,
        legal_entity: [
          database_id: :equal,
          edrpou: :equal,
          nhs_verified: :equal,
          nhs_reviewed: :equal,
          type: :equal
        ]
        # TODO: implement resolver-independent FTS
        # party: [full_name: :full_text_search]
      )

      resolve(&LegalEntityResolver.load_employees/3)
    end

    connection field(:divisions, node_type: :division) do
      arg(:filter, :division_filter)
      arg(:order_by, :division_order_by, default_value: :inserted_at_asc)

      middleware(Filtering,
        database_id: :equal,
        name: :like,
        dls_verified: :equal
      )

      resolve(&LegalEntityResolver.load_divisions/3)
    end

    field(:merged_to_legal_entity, :related_legal_entity, resolve: dataloader(PRM))

    connection field(:merged_from_legal_entities, node_type: :related_legal_entity) do
      arg(:filter, :related_legal_entity_filter)
      arg(:order_by, :related_legal_entity_order_by, default_value: :inserted_at_asc)

      middleware(Filtering,
        is_active: :equal,
        merged_to_legal_entity: [
          edrpou: :equal,
          is_active: :equal
        ],
        merged_from_legal_entity: {
          [edrpou: :equal, is_active: :equal],
          [field: :merged_from]
        }
      )

      resolve(&LegalEntityResolver.load_related_legal_entities/3)
    end

    # timestamps
    field(:inserted_at, :datetime)
    field(:updated_at, :datetime)
  end

  # embed

  object :license do
    field(:license_number, :string)
    field(:issued_by, :string)
    field(:issued_date, :string)
    field(:active_from_date, :string)
    field(:order_no, :string)
    field(:expiry_date, :string)
    field(:what_licensed, :string)
  end

  object :accreditation do
    field(:category, :string)
    field(:order_no, :string)
    field(:order_date, :string)
    field(:issued_date, :string)
    field(:expiry_date, :string)
  end

  object :legal_entity_archive do
    field(:date, :string)
    field(:place, :string)
  end

  # enum

  enum :legal_entity_status do
    value(:active, as: "ACTIVE")
    value(:closed, as: "CLOSED")
    value(:reorganized, as: "REORGANIZED")
    value(:suspended, as: "SUSPENDED")
  end

  enum :legal_entity_mis_verified do
    value(:verified, as: "VERIFIED")
    value(:not_verified, as: "NOT_VERIFIED")
  end
end
