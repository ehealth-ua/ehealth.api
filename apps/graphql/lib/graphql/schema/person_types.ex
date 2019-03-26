defmodule GraphQL.Schema.PersonTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Connection
  alias Absinthe.Relay.Node.ParseIDs
  alias Absinthe.Resolution
  alias GraphQL.Middleware.{Filtering, TransformInput}
  alias GraphQL.Resolvers.Person, as: PersonResolver

  object :person_queries do
    @desc "Get all persons"
    connection field(:persons, node_type: :person) do
      meta(:scope, ~w(person:read))
      arg(:filter, non_null(:person_filter))
      arg(:order_by, :person_order_by, default_value: :inserted_at_desc)

      middleware(&validate_persons_query_input/2)

      middleware(TransformInput, %{
        :birth_date => [:personal, :birth_date],
        :authentication_methods => [:personal, :authentication_method, :phone_number],
        :tax_id => [:identity, :tax_id],
        :unzr => [:identity, :unzr],
        :status => [:status],
        [:documents, :number] => [:identity, :document, :number],
        [:documents, :type] => [:identity, :document, :type]
      })

      middleware(&transform_persons_query_filter/2)

      middleware(Filtering,
        birth_date: :equal,
        authentication_methods: :contains,
        tax_id: :equal,
        unzr: :equal,
        status: :equal,
        documents: [
          type: :equal,
          number: :equal
        ]
      )

      resolve(&PersonResolver.list_persons/2)
    end

    @desc "Get person by id"
    field(:person, :person) do
      meta(:scope, ~w(person:read))
      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :person)
      resolve(&PersonResolver.get_person_by_id/3)
    end
  end

  input_object :person_filter do
    field(:personal, non_null(:person_personal_filter))
    field(:identity, non_null(:person_identity_filter))
    field(:status, :person_status)
  end

  input_object :person_personal_filter do
    field(:authentication_method, :authentication_method_filter)
    field(:birth_date, :date)
  end

  input_object :authentication_method_filter do
    field(:phone_number, :string)
  end

  input_object :person_identity_filter do
    field(:tax_id, :string)
    field(:unzr, :string)
    field(:document, :person_document_filter)
  end

  input_object :person_document_filter do
    # Dictionary: DOCUMENT_TYPE
    field(:type, non_null(:string))
    field(:number, non_null(:string))
  end

  enum :person_order_by do
    value(:birth_date_asc)
    value(:birth_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:tax_id_asc)
    value(:tax_id_desc)
    value(:unzr_asc)
    value(:unzr_desc)
  end

  connection node_type: :person do
    field :nodes, list_of(:person) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  object :person_mutations do
    payload field(:reset_person_authentication_method) do
      meta(:scope, ~w(person:reset_authentication_method))

      input do
        field(:person_id, non_null(:id))
      end

      output do
        field(:person, :person)
      end

      middleware(ParseIDs, id: :person)
      resolve(&PersonResolver.reset_authentication_method/2)
    end
  end

  node object(:person) do
    field(:database_id, non_null(:uuid))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:birth_date, non_null(:date))
    field(:email, :string)
    # Dictionary: GENDER
    field(:gender, non_null(:string), resolve: PersonResolver.resolve_upcased(:gender))
    field(:status, non_null(:person_status), resolve: PersonResolver.resolve_upcased(:status))
    field(:birth_country, non_null(:string))
    field(:birth_settlement, non_null(:string))
    field(:unzr, :string)
    field(:tax_id, :string)
    field(:no_tax_id, :boolean)

    field(:preferred_way_communication, :person_preferred_way_communication,
      resolve: PersonResolver.resolve_upcased(:person_preferred_way_communication)
    )

    field(:authentication_methods, non_null(list_of(:person_authentication_method)))
    field(:documents, list_of(:person_document))
    field(:addresses, non_null(list_of(:address)))
    field(:phones, list_of(:phone))

    field(:emergency_contact, non_null(:emergency_contact))
    field(:confidant_persons, list_of(:confidant_person), resolve: fn _, res -> {:ok, res.source.confidant_person} end)

    connection field(:declarations, node_type: :declaration) do
      arg(:order_by, :declaration_order_by)

      resolve(&PersonResolver.load_declarations/3)
    end

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  enum :person_status do
    value(:active, as: "ACTIVE")
    value(:inactive, as: "INACTIVE")
  end

  enum :person_preferred_way_communication do
    value(:email, as: "EMAIL")
    value(:phone, as: "PHONE")
  end

  object :person_authentication_method do
    # Dictionary: AUTHENTICATION_METHOD
    field(:type, non_null(:string))
    field(:phone_number, :string)
  end

  object :person_document do
    field(:type, :string)
    field(:number, :string)
    field(:issued_by, :string)

    # TODO: These fields should return :date type
    field(:issued_at, :string)
    field(:expiration_date, :string)
  end

  object :emergency_contact do
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:phones, non_null(list_of(:phone)))
  end

  object :confidant_person do
    # Dictionary: CONFIDANT_PERSON_TYPE
    field(:relation_type, non_null(:string))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    # TODO: This field should return :date type
    field(:birth_date, :string)
    field(:birth_country, non_null(:string))
    field(:birth_settlement, non_null(:string))
    # Dictionary: GENDER
    field(:gender, non_null(:string))
    field(:unzr, :string)
    field(:tax_id, :string)
    field(:email, :string)

    field(:preferred_way_communication, :person_preferred_way_communication,
      resolve: PersonResolver.resolve_upcased("person_preferred_way_communication")
    )

    field(:documents, non_null(list_of(:person_document)),
      resolve: fn _, res -> {:ok, res.source["documents_person"]} end
    )

    field(:relationship_documents, non_null(list_of(:person_document)),
      resolve: fn _, res -> {:ok, res.source["documents_relationship"]} end
    )

    field(:phones, list_of(:phone))
  end

  defp validate_persons_query_input(%{arguments: %{filter: filter}} = resolution, _) do
    if %{} in [filter[:personal], filter[:identity]] do
      Resolution.put_result(resolution, Connection.from_slice([], 0))
    else
      resolution
    end
  end

  defp transform_persons_query_filter(%{arguments: %{filter: filter} = arguments} = resolution, _params) do
    filter =
      case Map.get(filter, :authentication_methods) do
        nil -> filter
        phone_number -> %{filter | authentication_methods: [%{"phone_number" => phone_number}]}
      end

    %{resolution | arguments: %{arguments | filter: filter}}
  end
end
