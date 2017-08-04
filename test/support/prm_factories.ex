defmodule EHealth.PRMFactories do
  @moduledoc false

  use ExMachina.Ecto, repo: EHealth.PRMRepo

  use EHealth.PRMFactories.LegalEntityFactory
  use EHealth.PRMFactories.MedicalServiceProviderFactory
  use EHealth.PRMFactories.GlobalParameterFactory
end
