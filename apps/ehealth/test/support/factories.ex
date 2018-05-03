defmodule EHealth.Factories do
  @moduledoc false

  use ExMachina

  # PRM
  use EHealth.PRMFactories.LegalEntityFactory
  use EHealth.PRMFactories.MedicalServiceProviderFactory
  use EHealth.PRMFactories.GlobalParameterFactory
  use EHealth.PRMFactories.UkrMedRegistryFactory
  use EHealth.PRMFactories.DivisionFactory
  use EHealth.PRMFactories.EmployeeFactory
  use EHealth.PRMFactories.PartyFactory
  use EHealth.PRMFactories.MedicationFactory
  use EHealth.PRMFactories.MedicalProgramFactory
  use EHealth.PRMFactories.BlackListUserFactory

  # IL
  use EHealth.ILFactories.RegisterFactory
  use EHealth.ILFactories.DictionaryFactory
  use EHealth.ILFactories.EmployeeRequestFactory
  use EHealth.ILFactories.DeclarationRequestFactory
  use EHealth.ILFactories.ContractRequestFactory

  # OPS
  use EHealth.OPSFactories.DeclarationFactory
  use EHealth.OPSFactories.MedicationRequestFactory
  use EHealth.OPSFactories.MedicationDispenseFactory
  use EHealth.OPSFactories.MedicationDispenseDetailsFactory
  use EHealth.OPSFactories.ContractFactory

  # MPI
  use EHealth.MPIFactories.PersonFactory

  alias EHealth.Repo
  alias EHealth.PRMRepo

  def insert(type, factory, attrs \\ []) do
    factory
    |> build(attrs)
    |> repo_insert!(type)
  end

  def string_params_for(factory, attrs \\ []) do
    ExMachina.Ecto.string_params_for(__MODULE__, factory, attrs)
  end

  defp repo_insert!(data, :il), do: Repo.insert!(data)
  defp repo_insert!(data, :prm), do: PRMRepo.insert!(data)
end
