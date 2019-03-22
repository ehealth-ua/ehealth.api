defmodule GraphQL.Resolvers.INNMDosage do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  import Ecto.Query, only: [order_by: 2, where: 2]
  import GraphQL.Filters.Base, only: [filter: 2]

  alias Absinthe.Relay.Connection
  alias Core.Medications
  alias Core.Medications.INNMDosage

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_innm_dosages(%{filter: filter, order_by: order_by} = args, _) do
    INNMDosage
    |> where(type: ^INNMDosage.type())
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    ingredients = Enum.map(args.ingredients, &(&1 |> Map.put(:id, &1.innm_id) |> Map.delete(:innm_id)))
    args = atoms_to_strings(%{args | ingredients: ingredients})

    with {:ok, innm_dosage} <- Medications.create_innm_dosage(args, consumer_id) do
      {:ok, %{innm_dosage: innm_dosage}}
    end
  end

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, innm_dosage} <- Medications.fetch_innm_dosage_by_id(id),
         {:ok, innm_dosage} <- Medications.deactivate_innm_dosage(innm_dosage, consumer_id) do
      {:ok, %{innm_dosage: innm_dosage}}
    end
  end
end
