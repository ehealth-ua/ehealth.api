defmodule Core.PRMFactories.MedicalProgramFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def medical_program_factory do
        %Core.MedicalPrograms.MedicalProgram{
          name: "Доступні ліки",
          is_active: true,
          type: "MEDICATION",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
