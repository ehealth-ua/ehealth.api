defmodule GraphQLWeb.Schema.EmployeeTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Core.Employees.Employee
  alias GraphQLWeb.Loaders.EmployeeLoader
  alias GraphQLWeb.Resolvers.LegalEntity

  @type_admin Employee.type(:admin)
  @type_owner Employee.type(:owner)
  @type_doctor Employee.type(:doctor)
  @type_pharmacist Employee.type(:pharmacist)
  @type_pharmacy_owner Employee.type(:pharmacy_owner)

  @status_new Employee.status(:new)
  @status_approved Employee.status(:approved)
  @status_dismissed Employee.status(:dismissed)

  object :employee do
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
    field(:party, non_null(:party), resolve: dataloader(EmployeeLoader))
    field(:division, :division, resolve: dataloader(EmployeeLoader))
    field(:legal_entity, non_null(:legal_entity), resolve: dataloader(LegalEntity))
  end

  input_object :employee_filter do
    field(:employee_type, :employee_type)
    field(:status, :employee_status)
    field(:is_active, :boolean)
  end

  enum :employee_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:employee_type_asc)
    value(:employee_type_desc)
    value(:status_asc)
    value(:status_desc)
  end

  # embed

  object :party do
    field(:database_id, non_null(:id))
    field(:first_name, non_null(:string))
    field(:last_name, non_null(:string))
    field(:second_name, :string)
    field(:birth_date, non_null(:string))
    field(:gender, non_null(:gender))
    field(:phones, list_of(:phone))
  end

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
  enum :gender do
    value(:male, as: "MALE")
    value(:female, as: "FEMALE")
  end

  enum :employee_status do
    value(:new, as: @status_new)
    value(:approved, as: @status_approved)
    value(:dismissed, as: @status_dismissed)
  end

  enum :employee_type do
    value(:admin, as: @type_admin)
    value(:owner, as: @type_owner)
    value(:doctor, as: @type_doctor)
    value(:pharmacist, as: @type_pharmacist)
    value(:pharmacy_owner, as: @type_pharmacy_owner)
  end
end
