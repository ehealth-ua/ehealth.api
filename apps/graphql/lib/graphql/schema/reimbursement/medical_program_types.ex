defmodule GraphQL.Schema.MedicalProgramTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.MedicalPrograms.MedicalProgram
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.MedicalProgram, as: MedicalProgramResolver

  object :medical_program_queries do
    connection field(:medical_programs, node_type: :medical_program) do
      meta(:scope, ~w(medical_program:read))

      arg(:filter, :medical_program_filter)
      arg(:order_by, :medical_program_order_by, default_value: :inserted_at_desc)

      middleware(Filtering, database_id: :equal, name: :like, is_active: :equal)

      resolve(&MedicalProgramResolver.list_medical_programs/2)
    end

    field :medical_program, :medical_program do
      meta(:scope, ~w(medical_program:read))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :medical_program)

      resolve(load_by_args(PRM, MedicalProgram))
    end
  end

  input_object :medical_program_filter do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:is_active, :boolean)
  end

  enum :medical_program_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection node_type: :medical_program do
    field :nodes, list_of(:medical_program) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  object :medical_program_mutations do
    payload field(:create_medical_program) do
      meta(:scope, ~w(medical_program:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:name, non_null(:string))
      end

      output do
        field(:medical_program, :medical_program)
      end

      middleware(ParseIDs, id: :medical_program)
      resolve(&MedicalProgramResolver.create/2)
    end

    payload field(:deactivate_medical_program) do
      meta(:scope, ~w(medical_program:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:medical_program, :medical_program)
      end

      middleware(ParseIDs, id: :medical_program)
      resolve(&MedicalProgramResolver.deactivate/2)
    end
  end

  node object(:medical_program) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:is_active, non_null(:boolean))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
