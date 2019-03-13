defmodule GraphQL.Resolvers.CapitationContractRequest do
  @moduledoc false

  use GraphQL.Resolvers.ContractRequest,
    schema: Core.ContractRequests.CapitationContractRequest,
    restricted_client_type: "MSP"
end
