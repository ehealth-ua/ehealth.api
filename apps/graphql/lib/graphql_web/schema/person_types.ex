defmodule GraphQLWeb.Schema.PersonTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQLWeb.Resolvers.PersonResolver

  object :person_queries do
    @desc "Get all persons"
    connection field(:persons, node_type: :person) do
      meta(:scope, ~w(person:list))
      arg(:filter, non_null(:person_filter))
      arg(:order_by, :person_order_by, default_value: :inserted_at_desc)

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
    field(:documents, non_null(:person_documents_filter))
  end

  input_object :person_personal_filter do
    field(:authentication_method, :authentication_method_filter)
    field(:birth_date, :date)
  end

  input_object :authentication_method_filter do
    field(:phone_number, :string)
  end

  input_object :person_documents_filter do
    field(:tax_id, :string)
    field(:number, :string)
  end

  enum :person_order_by do
    value(:birth_date_asc)
    value(:birth_date_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:tax_id_asc)
    value(:tax_id_desc)
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

  node object(:person) do
    field(:database_id, non_null(:id))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:birth_date, non_null(:date))
    field(:gender, non_null(:person_gender), resolve: PersonResolver.resolve_upcased(:gender))
    field(:status, non_null(:person_status), resolve: PersonResolver.resolve_upcased(:status))
    field(:birth_country, non_null(:string))
    field(:birth_settlement, non_null(:string))
    field(:unzr, :string)
    field(:tax_id, :string)
    field(:no_tax_id, :boolean)

    field(:preferred_way_communication, :person_preferred_way_communication,
      resolve: PersonResolver.resolve_upcased(:person_preferred_way_communication)
    )

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
    field(:authentication_methods, non_null(list_of(:person_authentication_method)))
    field(:documents, list_of(:person_document))
    field(:addresses, non_null(list_of(:address)))
    field(:phones, list_of(:phone))
    # field :declarations, list_of(:declaration) do
    #   arg(:filter, :declaration_filter)
    #   arg(:order_by, :declaration_order_by)
    # end
  end

  enum :person_status do
    value(:active, as: "ACTIVE")
    value(:inactive, as: "INACTIVE")
  end

  enum :person_gender do
    value(:female, as: "FEMALE")
    value(:male, as: "MALE")
  end

  enum :person_preferred_way_communication do
    value(:email, as: "EMAIL")
    value(:phone, as: "PHONE")
  end

  object :person_authentication_method do
    field(:type, non_null(:person_authentication_method_type))
    field(:phone_number, :string)
  end

  enum :person_authentication_method_type do
    value(:na, as: "NA")
    value(:offline, as: "OFFLINE")
    value(:otp, as: "OTP")
  end

  object :person_document do
    field(:type, :string)
    field(:number, :string)
    field(:issued_by, :string)

    # Has :string type on MPI
    field(:issued_at, :string)
  end
end
