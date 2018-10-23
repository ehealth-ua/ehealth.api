defmodule GraphQLWeb.Schema.DivisionTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  alias Core.Divisions.Division

  @active Division.status(:active)
  @inactive Division.status(:inactive)

  @type_clinic Division.type(:clinic)
  @type_ambulant_clinic Division.type(:ambulant_clinic)
  @type_fap Division.type(:fap)

  object :division do
    field(:database_id, non_null(:id))
    field(:name, non_null(:string))
    field(:email, non_null(:string))
    field(:employee_type, non_null(:string))
    field(:mountain_group, non_null(:boolean))
    field(:is_active, non_null(:boolean))
    #    field(:working_hours, :division_working_hours)

    # enums
    field(:type, non_null(:division_type))
    field(:status, non_null(:division_status))

    # embed

    field(:phones, non_null(list_of(:phone)))
    field(:addresses, non_null(list_of(:address)))
  end

  input_object :division_filter do
    field(:name, :string)
    field(:is_active, :boolean)
  end

  enum :division_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  # enum

  enum :division_status do
    value(:active, as: @active)
    value(:inactive, as: @inactive)
  end

  enum :division_type do
    value(:clinit, as: @type_clinic)
    value(:ambulant_clinic, as: @type_ambulant_clinic)
    value(:fap, as: @type_fap)
  end

  # embed
  # ToDo: map :hours field
  object :division_working_hours do
    #    field(:days, list_of(:week_day))
    #    field(:hours, list_of(:time_range))
  end
end
