defmodule GraphQL.Schema do
  @moduledoc false

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  use GraphQL.Middleware.{
    MapGet,
    FormatErrors,
    DatabaseIDs,
    OrderByArgument,
    ClientAuthorization,
    ClientMetadata,
    ScopeAuthorization
  }

  alias Core.ContractRequests.{CapitationContractRequest, ReimbursementContractRequest}
  alias Core.Contracts.{CapitationContract, ReimbursementContract}
  alias Core.Declarations.Declaration
  alias Core.Dictionaries.Dictionary
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.{LegalEntity, RelatedLegalEntity}
  alias Core.ManualMerge.ManualMergeRequest
  alias Core.MedicalPrograms.MedicalProgram
  alias Core.Medications.{INNM, INNMDosage, Medication}
  alias Core.Medications.Program, as: ProgramMedication
  alias Core.Persons.Person
  alias GraphQL.Loaders.{IL, ManualMerger, MPI, OPS, PRM, Uaddresses}

  import_types(Absinthe.Type.Custom)

  import_types(GraphQL.Schema.{
    ScalarTypes,
    AddressTypes,
    PhoneTypes,
    SignedContentTypes,
    ContractRequestTypes,
    CapitationContractRequestTypes,
    ReimbursementContractRequestTypes,
    ContractTypes,
    CapitationContractTypes,
    ReimbursementContractTypes,
    DeclarationTypes,
    DictionaryTypes,
    DivisionTypes,
    EmployeeTypes,
    EmployeeRequestTypes,
    LegalEntityTypes,
    RelatedLegalEntityTypes,
    LegalEntityMergeJobTypes,
    LegalEntityDeactivationJobTypes,
    MedicalProgramTypes,
    MergeRequestTypes,
    PartyTypes,
    PersonTypes,
    RegionTypes,
    DistrictTypes,
    SettlementTypes,
    INNMDosageTypes,
    INNMTypes,
    IngredientTypes,
    MedicationTypes,
    ProgramMedicationTypes
  })

  query do
    import_fields(:capitation_contract_queries)
    import_fields(:reimbursement_contract_queries)
    import_fields(:capitation_contract_request_queries)
    import_fields(:reimbursement_contract_request_queries)
    import_fields(:employee_queries)
    import_fields(:employee_request_queries)
    import_fields(:dictionary_queries)
    import_fields(:declaration_queries)
    import_fields(:legal_entity_queries)
    import_fields(:legal_entity_merge_job_queries)
    import_fields(:legal_entity_deactivation_job_queries)
    import_fields(:medical_program_queries)
    import_fields(:program_medication_queries)
    import_fields(:medication_queries)
    import_fields(:innm_dosage_queries)
    import_fields(:innm_queries)
    import_fields(:person_queries)
    import_fields(:merge_request_queries)
    import_fields(:settlement_queries)
  end

  mutation do
    import_fields(:contract_mutations)
    import_fields(:contract_request_mutations)
    import_fields(:employee_mutations)
    import_fields(:declaration_mutations)
    import_fields(:dictionary_mutations)
    import_fields(:innm_mutations)
    import_fields(:employee_request_mutations)
    import_fields(:legal_entity_mutations)
    import_fields(:legal_entity_merge_job_mutations)
    import_fields(:legal_entity_deactivation_job_mutations)
    import_fields(:medical_program_mutations)
    import_fields(:program_medication_mutations)
    import_fields(:medication_mutations)
    import_fields(:innm_dosage_mutations)
    import_fields(:person_mutations)
    import_fields(:merge_request_mutations)
  end

  node interface do
    resolve_type(fn
      %CapitationContract{}, _ -> :capitation_contract
      %ReimbursementContract{}, _ -> :reimbursement_contract
      %CapitationContractRequest{}, _ -> :capitation_contract_request
      %ReimbursementContractRequest{}, _ -> :reimbursement_contract_request
      %Declaration{}, _ -> :declaration
      %Dictionary{}, _ -> :dictionary
      %Division{}, _ -> :division
      %Employee{}, _ -> :employee
      %LegalEntity{}, _ -> :legal_entity
      %RelatedLegalEntity{}, _ -> :related_legal_entity
      %MedicalProgram{}, _ -> :medical_program
      %Medication{}, _ -> :medication
      %INNM{}, _ -> :innm
      %INNMDosage{}, _ -> :innm_dosage
      %ProgramMedication{}, _ -> :program_medication
      %ManualMergeRequest{}, _ -> :merge_request
      %Person{}, _ -> :person
      _, _ -> nil
    end)
  end

  def context(ctx) do
    loader =
      Dataloader.new(get_policy: :return_nil_on_error)
      |> Dataloader.add_source(IL, IL.data())
      |> Dataloader.add_source(PRM, PRM.data())
      |> Dataloader.add_source(OPS, OPS.data())
      |> Dataloader.add_source(MPI, MPI.data())
      |> Dataloader.add_source(Uaddresses, Uaddresses.data())
      |> Dataloader.add_source(ManualMerger, ManualMerger.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end
end
