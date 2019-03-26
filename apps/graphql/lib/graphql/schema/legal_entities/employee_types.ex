defmodule GraphQL.Schema.EmployeeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Employees.Employee
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.Employee, as: EmployeeResolver

  object :employee_queries do
    connection field(:employees, node_type: :employee) do
      meta(:scope, ~w(employee:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:filter, :employee_filter)
      arg(:order_by, :employee_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        employee_type: :in,
        position: :in,
        start_date: :in,
        status: :equal,
        is_active: :equal,
        party: [
          full_name: :full_text_search,
          no_tax_id: :equal
        ],
        division: [name: :like],
        legal_entity: [
          database_id: :equal,
          edrpou: :equal,
          name: :like,
          nhs_verified: :equal,
          nhs_reviewed: :equal,
          type: :equal
        ]
      )

      resolve(&EmployeeResolver.list_employees/2)
    end

    field :employee, :employee do
      meta(:scope, ~w(employee:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS MSP))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :employee)

      resolve(
        load_by_args(PRM, fn _args, %{context: context} ->
          {Employee, Map.take(context, ~w(client_id client_type)a)}
        end)
      )
    end
  end

  input_object :employee_filter do
    field(:database_id, :uuid)
    # Dictionary: EMPLOYEE_TYPE
    field(:employee_type, list_of(:string))
    field(:position, list_of(:string))
    field(:start_date, :date_interval)
    # Dictionary: EMPLOYEE_STATUS
    field(:status, :string)
    field(:is_active, :boolean)
    field(:party, :party_filter)
    field(:division, :division_filter)
    field(:legal_entity, :legal_entity_filter)
  end

  enum :employee_order_by do
    value(:division_name_asc)
    value(:division_name_desc)
    value(:employee_type_asc)
    value(:employee_type_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:legal_entity_name_asc)
    value(:legal_entity_name_desc)
    value(:party_full_name_asc)
    value(:party_full_name_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection(node_type: :employee) do
    field :nodes, list_of(:employee) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  object :employee_mutations do
    payload field(:deactivate_employee) do
      meta(:scope, ~w(employee:write))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:employee, :employee)
      end

      middleware(ParseIDs, id: :employee)
      resolve(&EmployeeResolver.deactivate_employee/2)
    end
  end

  node object(:employee) do
    field(:database_id, non_null(:uuid))
    field(:position, non_null(:string))
    field(:start_date, non_null(:date))
    field(:end_date, :date)
    field(:is_active, :boolean)
    # Dictionary: EMPLOYEE_TYPE
    field(:employee_type, non_null(:string))
    # Dictionary: EMPLOYEE_STATUS
    field(:status, non_null(:string))

    # embed
    field(:additional_info, :employee_additional_info)

    # relations
    field(:party, non_null(:party), resolve: dataloader(PRM))
    field(:division, :division, resolve: dataloader(PRM))
    field(:legal_entity, non_null(:legal_entity), resolve: dataloader(PRM))

    # timestamps
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  # embed

  object :employee_additional_info do
    field(:specialities, list_of(:speciality))
    field(:educations, list_of(:education))
    field(:qualifications, list_of(:qualification))
    field(:science_degree, list_of(:science_degree))
  end

  object :speciality do
    field(:speciality, non_null(:string))
    field(:speciality_officio, non_null(:boolean))
    field(:level, non_null(:string))
    field(:qualification_type, non_null(:string))
    field(:attestation_name, non_null(:string))
    field(:attestation_date, non_null(:string))
    field(:certificate_number, non_null(:string))
    field(:valid_to_date, :string)
  end

  object :education do
    field(:city, non_null(:string))
    field(:country, non_null(:string))
    field(:degree, non_null(:string))
    field(:diploma_number, non_null(:string))
    field(:institution_name, non_null(:string))
    # TODO: Should be date type
    field(:issued_date, :string)
    field(:speciality, non_null(:string))
  end

  object :qualification do
    field(:certificate_number, :string)
    field(:institution_name, non_null(:string))
    # TODO: Should be date type
    field(:issued_date, :string)
    field(:speciality, non_null(:string))
    field(:type, non_null(:string))
  end

  object :science_degree do
    field(:city, non_null(:string))
    field(:country, non_null(:string))
    field(:degree, non_null(:string))
    field(:diploma_number, non_null(:string))
    field(:institution_name, non_null(:string))
    # TODO: Should be date type
    field(:issued_date, :string)
    field(:speciality, non_null(:string))
  end
end
