defmodule GraphQL.Resolvers.Medication do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  import Ecto.Query, only: [where: 2, order_by: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Medications
  alias Core.Medications.Medication

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_medications(%{filter: filter, order_by: order_by} = args, _) do
    Medication
    |> where(type: ^Medication.type())
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    args =
      args
      |> prepare_ingredients()
      |> prepare_code_atc()
      |> atoms_to_strings()

    with {:ok, medication} <- Medications.create_medication(args, consumer_id) do
      {:ok, %{medication: medication}}
    end
  end

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, medication} <- Medications.fetch_medication_by_id(id),
         {:ok, medication} <- Medications.deactivate_medication(medication, consumer_id) do
      {:ok, %{medication: medication}}
    end
  end

  defp prepare_ingredients(%{ingredients: ingredients} = args) do
    ingredients = Enum.map(ingredients, &(&1 |> Map.put(:id, &1.innm_dosage_id) |> Map.delete(:innm_dosage_id)))
    %{args | ingredients: ingredients}
  end

  defp prepare_code_atc(args) do
    args
    |> Map.put(:code_atc, args.atc_codes)
    |> Map.delete(:atc_codes)
  end
end
