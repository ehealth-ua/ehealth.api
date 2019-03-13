defmodule GraphQL.Resolvers.ReimbursementContractRequest do
  @moduledoc false

  use GraphQL.Resolvers.ContractRequest,
    schema: Core.ContractRequests.ReimbursementContractRequest,
    restricted_client_type: "PHARMACY"
end
