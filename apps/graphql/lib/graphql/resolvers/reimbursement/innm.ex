defmodule GraphQL.Resolvers.INNM do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  import GraphQL.Filters.Base, only: [filter: 2]
  import Ecto.Query, only: [order_by: 2]

  alias Absinthe.Relay.Connection
  alias Core.Medications
  alias Core.Medications.INNM

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_innms(%{filter: filter, order_by: order_by} = args, _) do
    INNM
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, innm} <- Medications.create_innm(atoms_to_strings(args), consumer_id) do
      {:ok, %{innm: innm}}
    end
  end
end
