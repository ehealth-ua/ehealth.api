defmodule GraphQLWeb.Resolvers.ReimbursementContractResolver do
  @moduledoc false

  use GraphQLWeb.Resolvers.ContractResolver,
    schema: Core.Contracts.ReimbursementContract,
    request_schema: Core.ContractRequests.ReimbursementContractRequest,
    restricted_client_type: "PHARMACY"
end
