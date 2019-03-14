defmodule GraphQL.Resolvers.Medication do
  @moduledoc false

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

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, medication} <- Medications.fetch_medication_by_id(id),
         {:ok, medication} <- Medications.deactivate_medication(medication, consumer_id) do
      {:ok, %{medication: medication}}
    end
  end
end
