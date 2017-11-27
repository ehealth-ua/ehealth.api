defmodule EHealth.PRMFactories.UkrMedRegistryFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID
      alias EHealth.LegalEntities.Registry

      def registry_factory do
        %Registry{
          name: sequence(:name, &"registry row #{&1}"),
          edrpou: "37367387",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          type: Registry.type(:msp)
        }
      end
    end
  end
end
