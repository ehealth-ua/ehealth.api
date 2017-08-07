defmodule EHealth.PRMFactories do
  @moduledoc false

  use ExMachina.Ecto, repo: EHealth.PRMRepo

  use EHealth.PRMFactories.LegalEntityFactory
  use EHealth.PRMFactories.MedicalServiceProviderFactory
  use EHealth.PRMFactories.GlobalParameterFactory
  use EHealth.PRMFactories.UkrMedRegistryFactory
  use EHealth.PRMFactories.DivisionFactory
  use EHealth.PRMFactories.EmployeeFactory
  use EHealth.PRMFactories.EmployeeDoctorFactory
  use EHealth.PRMFactories.PartyFactory
end
