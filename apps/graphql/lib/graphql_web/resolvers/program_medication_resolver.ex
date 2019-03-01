defmodule GraphQLWeb.Resolvers.ProgramMedicationResolver do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Medications
  alias Core.Medications.Program, as: ProgramMedication

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_program_medications(%{filter: filter, order_by: order_by} = args, _resolution) do
    ProgramMedication
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def get_program_medication_by_id(_parent, %{id: id}, _resolution) do
    Medications.fetch_program_medication(id: id)
  end

  def create_program_medication(args, %{context: %{consumer_id: consumer_id}}) do
    args = atoms_to_strings(args)

    with {:ok, program_medication} <- Medications.create_program_medication(args, consumer_id) do
      {:ok, %{program_medication: program_medication}}
    end
  end

  def update_program_medication(args, %{context: %{consumer_id: consumer_id}}) do
    {id, args} = Map.pop(args, :id)
    args = atoms_to_strings(args)

    with {:ok, program_medication} <- Medications.fetch_program_medication(id: id),
         {:ok, program_medication} <- Medications.update_program_medication(program_medication, args, consumer_id) do
      {:ok, %{program_medication: program_medication}}
    end
  end
end
