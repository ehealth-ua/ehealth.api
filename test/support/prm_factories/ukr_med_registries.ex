defmodule EHealth.PRMFactories.UkrMedRegistryFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def registry_factory do
        %EHealth.PRM.Registries.Schema{
          name: sequence(:name, &"registry row #{&1}"),
          edrpou: "37367387",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
        }
      end
    end
  end
end
