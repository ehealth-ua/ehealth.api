defmodule GraphQLWeb.Schema.EmployeeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Employees.Employee
  alias GraphQLWeb.Loaders.PRM
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.EmployeeResolver

  @type_admin Employee.type(:admin)
  @type_doctor Employee.type(:doctor)
  @type_hr Employee.type(:hr)
  @type_nhs Employee.type(:nhs)
  @type_nhs_signer Employee.type(:nhs_signer)
  @type_owner Employee.type(:owner)
  @type_pharmacist Employee.type(:pharmacist)
  @type_pharmacy_owner Employee.type(:pharmacy_owner)

  @status_approved Employee.status(:approved)
  @status_dismissed Employee.status(:dismissed)
  @status_new Employee.status(:new)

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
        status: :equal,
        is_active: :equal,
        legal_entity: [database_id: :equal, edrpou: :equal, nhs_verified: :equal, nhs_reviewed: :equal],
        party: [full_name: :full_text_search]
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
    field(:database_id, :id)
    field(:employee_type, list_of(:employee_type))
    field(:status, :employee_status)
    field(:is_active, :boolean)
    field(:legal_entity, :legal_entity_filter)
    field(:party, :party_filter)
  end

  enum :employee_order_by do
    value(:employee_type_asc)
    value(:employee_type_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
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

  node object(:employee) do
    field(:database_id, non_null(:id))
    field(:position, non_null(:string))
    field(:start_date, non_null(:string))
    field(:end_date, :string)
    field(:is_active, :boolean)

    # enums
    field(:employee_type, non_null(:employee_type))
    field(:status, non_null(:employee_status))

    # embed
    field(:additional_info, :employee_additional_info)

    # relations
    field(:party, non_null(:party), resolve: dataloader(PRM))
    field(:division, :division, resolve: dataloader(PRM))
    field(:legal_entity, non_null(:legal_entity), resolve: dataloader(PRM))

    # timestamps
    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  # embed

  object :employee_additional_info do
    field(:specialities, list_of(:speciality))
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

  # enum
  enum :employee_type do
    value(:admin, as: @type_admin)
    value(:doctor, as: @type_doctor)
    value(:hr, as: @type_hr)
    value(:nhs, as: @type_nhs)
    value(:nhs_signer, as: @type_nhs_signer)
    value(:owner, as: @type_owner)
    value(:pharmacist, as: @type_pharmacist)
    value(:pharmacy_owner, as: @type_pharmacy_owner)
  end

  enum :employee_status do
    value(:approved, as: @status_approved)
    value(:dismissed, as: @status_dismissed)
    value(:new, as: @status_new)
  end
end
