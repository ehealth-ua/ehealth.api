defmodule GraphQL.Schema.EmployeeRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import GraphQL.Resolvers.EmployeeRequest, only: [resolve_data: 1]

  alias GraphQL.Resolvers.EmployeeRequest, as: EmployeeRequestResolver

  object :employee_request_mutations do
    payload field(:create_employee_request) do
      meta(:scope, ~w(employee_request:create))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS MSP PHARMACY MSP_PHARMACY))

      input do
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:employee_request, :employee_request)
      end

      resolve(&EmployeeRequestResolver.create_employee_request/2)
    end
  end

  node object(:employee_request) do
    field(:database_id, non_null(:uuid))
    field(:birth_date, non_null(:string), resolve: resolve_data(~w(party birth_date)))
    field(:email, non_null(:string), resolve: resolve_data(~w(party email)))
    field(:employee_type, non_null(:string), resolve: resolve_data(~w(employee_type)))
    field(:first_name, non_null(:string), resolve: resolve_data(~w(party first_name)))
    field(:second_name, :string, resolve: resolve_data(~w(party second_name)))
    field(:last_name, non_null(:string), resolve: resolve_data(~w(party last_name)))
    # TODO: resolve no_tax_id
    field(:no_tax_id, :boolean)
    field(:status, non_null(:string))
    field(:tax_id, non_null(:string), resolve: resolve_data(~w(party tax_id)))
    field(:legal_entity, non_null(:legal_entity), resolve: &EmployeeRequestResolver.resolve_legal_entity/3)

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
