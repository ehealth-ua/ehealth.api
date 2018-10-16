defmodule GraphQLWeb.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern
  use GraphQLWeb.Middleware.MapGet
  use GraphQLWeb.Middleware.Authorization
  use GraphQLWeb.Middleware.ParseIDs
  use GraphQLWeb.Middleware.FilterArgument
  use GraphQLWeb.Middleware.OrderByArgument
  use GraphQLWeb.Middleware.DatabaseIDs

  alias Core.LegalEntities.LegalEntity
  alias Core.Persons.Person

  import_types(Absinthe.Type.Custom)

  import_types(GraphQLWeb.Schema.{
    AddressTypes,
    LegalEntityTypes,
    LegalEntityMergeJobTypes,
    PersonTypes,
    PhoneTypes,
    SignedContentTypes
  })

  query do
    import_fields(:legal_entity_queries)
    import_fields(:legal_entity_merge_job_queries)
    import_fields(:person_queries)
  end

  mutation do
    import_fields(:legal_entity_merge_job_mutations)
  end

  node interface do
    resolve_type(fn
      %LegalEntity{}, _ -> :legal_entity
      %Person{}, _ -> :person
      _, _ -> nil
    end)
  end
end
