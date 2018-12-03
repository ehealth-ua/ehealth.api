defmodule GraphQLWeb.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  use GraphQLWeb.Middleware.{
    MapGet,
    DatabaseIDs,
    OrderByArgument,
    ClientAuthorization,
    ClientMetadata,
    ScopeAuthorization
  }

  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Contracts.CapitationContract
  alias Core.Dictionaries.Dictionary
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.Persons.Person
  alias GraphQLWeb.Loaders.{IL, PRM}
  alias TasKafka.Job

  import_types(Absinthe.Type.Custom)

  import_types(GraphQLWeb.Schema.{
    ScalarTypes,
    AddressTypes,
    CapitationContractRequestTypes,
    ContractRequestTypes,
    ContractTypes,
    DictionaryTypes,
    DivisionTypes,
    EmployeeTypes,
    LegalEntityTypes,
    LegalEntityMergeJobTypes,
    PersonTypes,
    PhoneTypes,
    RelatedLegalEntityTypes,
    SignedContentTypes
  })

  query do
    import_fields(:capitation_contract_request_queries)
    import_fields(:contract_queries)
    import_fields(:employee_queries)
    import_fields(:dictionary_queries)
    import_fields(:legal_entity_queries)
    import_fields(:legal_entity_merge_job_queries)
    import_fields(:person_queries)
  end

  mutation do
    import_fields(:contract_mutations)
    import_fields(:contract_request_mutations)
    import_fields(:dictionary_mutations)
    import_fields(:legal_entity_mutations)
    import_fields(:legal_entity_merge_job_mutations)
  end

  node interface do
    resolve_type(fn
      %CapitationContract{}, _ -> :capitation_contract
      %CapitationContractRequest{}, _ -> :capitation_contract_request
      %Dictionary{}, _ -> :dictionary
      %Division{}, _ -> :division
      %Employee{}, _ -> :employee
      %LegalEntity{}, _ -> :legal_entity
      %RelatedLegalEntity{}, _ -> :related_legal_entity
      %Person{}, _ -> :person
      %Job{}, _ -> :legal_entity_merge_job
      _, _ -> nil
    end)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(IL, IL.data())
      |> Dataloader.add_source(PRM, PRM.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end
end
