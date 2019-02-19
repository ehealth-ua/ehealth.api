defmodule Core.Factories do
  @moduledoc false

  use ExMachina

  # PRM
  use Core.PRMFactories.LegalEntityFactory
  use Core.PRMFactories.MedicalServiceProviderFactory
  use Core.PRMFactories.GlobalParameterFactory
  use Core.PRMFactories.UkrMedRegistryFactory
  use Core.PRMFactories.DivisionFactory
  use Core.PRMFactories.EmployeeFactory
  use Core.PRMFactories.PartyFactory
  use Core.PRMFactories.MedicationFactory
  use Core.PRMFactories.MedicalProgramFactory
  use Core.PRMFactories.BlackListUserFactory
  use Core.PRMFactories.ContractFactory

  # IL
  use Core.ILFactories.RegisterFactory
  use Core.ILFactories.DictionaryFactory
  use Core.ILFactories.EmployeeRequestFactory
  use Core.ILFactories.DeclarationRequestFactory
  use Core.ILFactories.ContractRequestFactory

  # OPS
  use Core.OPSFactories.DeclarationFactory
  use Core.OPSFactories.MedicationRequestFactory
  use Core.OPSFactories.MedicationDispenseFactory
  use Core.OPSFactories.MedicationDispenseDetailsFactory

  # MPI
  use Core.MPIFactories.PersonFactory
  use Core.MPIFactories.ManualMergeFactory

  # Uaddresses
  use Core.UaddressesFactories.RegionFactory
  use Core.UaddressesFactories.DistrictFactory
  use Core.UaddressesFactories.SettlementFactory

  # Other factories
  use Core.Factories.AddressFactory

  alias Core.PRMRepo
  alias Core.Repo
  alias Core.Utils.TypesConverter

  def insert(type, factory, attrs \\ []) do
    factory
    |> build(attrs)
    |> repo_insert!(type)
  end

  def insert_list(count, type, factory, attrs \\ []) when count >= 1 do
    for _ <- 1..count, do: insert(type, factory, attrs)
  end

  def string_params_for(factory, attrs \\ %{}) do
    attrs = TypesConverter.strings_to_keys(attrs)

    factory
    |> build(attrs)
    |> TypesConverter.atoms_to_strings()
  end

  defp repo_insert!(data, :il), do: Repo.insert!(data)
  defp repo_insert!(data, :prm), do: PRMRepo.insert!(data)
end
