defmodule GraphQLWeb.Resolvers.CapitationContractRequestResolver do
  @moduledoc false

  use GraphQLWeb.Resolvers.ContractRequestResolver,
    schema: Core.ContractRequests.CapitationContractRequest,
    restricted_client_type: "MSP"
end
