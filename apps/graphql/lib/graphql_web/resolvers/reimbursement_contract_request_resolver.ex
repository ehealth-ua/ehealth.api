defmodule GraphQLWeb.Resolvers.ReimbursementContractRequestResolver do
  @moduledoc false

  use GraphQLWeb.Resolvers.ContractRequestResolver,
    schema: Core.ContractRequests.ReimbursementContractRequest,
    restricted_client_type: "PHARMACY"
end
