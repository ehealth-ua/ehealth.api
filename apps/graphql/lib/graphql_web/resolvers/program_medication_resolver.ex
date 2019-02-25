defmodule GraphQLWeb.Resolvers.ProgramMedicationsResolver do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]

  alias Core.Medications

  def create_program_medication(args, %{context: %{consumer_id: consumer_id}}) do
    args = atoms_to_strings(args)

    with {:ok, program_medication} <- Medications.create_program_medication(args, consumer_id) do
      {:ok, %{program_medication: program_medication}}
    end
  end
end
