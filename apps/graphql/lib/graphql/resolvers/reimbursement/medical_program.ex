defmodule GraphQL.Resolvers.MedicalProgram do
  @moduledoc false

  import GraphQL.Filters.Base, only: [filter: 2]
  import Ecto.Query, only: [order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.MedicalPrograms
  alias Core.MedicalPrograms.MedicalProgram

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_medical_programs(%{filter: filter, order_by: order_by} = args, _) do
    MedicalProgram
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, medical_program} <- MedicalPrograms.create(consumer_id, args) do
      {:ok, %{medical_program: medical_program}}
    end
  end

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, medical_program} <- MedicalPrograms.fetch_by_id(id),
         {:ok, medical_program} <- MedicalPrograms.deactivate(consumer_id, medical_program) do
      {:ok, %{medical_program: medical_program}}
    end
  end
end
