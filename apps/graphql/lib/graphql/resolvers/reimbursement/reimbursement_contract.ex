defmodule GraphQL.Resolvers.ReimbursementContract do
  @moduledoc false

  use GraphQL.Resolvers.Contract,
    schema: Core.Contracts.ReimbursementContract,
    request_schema: Core.ContractRequests.ReimbursementContractRequest,
    restricted_client_type: "PHARMACY"
end
