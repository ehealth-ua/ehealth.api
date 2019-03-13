defmodule GraphQL.Resolvers.CapitationContract do
  @moduledoc false

  use GraphQL.Resolvers.Contract,
    schema: Core.Contracts.CapitationContract,
    request_schema: Core.ContractRequests.CapitationContractRequest,
    restricted_client_type: "MSP"

  def load_contract_employees(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :contract_employees)
  end
end
