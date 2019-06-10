defmodule GraphQL.Resolvers.Service do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.ServiceCatalog, only: [filter: 2]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_parent_with_connection: 4]

  alias Absinthe.Relay.Connection
  alias Core.Services
  alias Core.Services.Service

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_services(%{filter: filter, order_by: order_by} = args, _context) do
    Service
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def load_service_groups(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :service_groups)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    args = atoms_to_strings(args)

    with {:ok, service} <- Services.create_service(args, consumer_id) do
      {:ok, %{service: service}}
    end
  end

  def update(%{id: id} = args, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, service} <- Services.fetch_by_id(Service, id),
         {:ok, service} <- Services.update(service, args, consumer_id) do
      {:ok, %{service: service}}
    end
  end

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, service} <- Services.fetch_by_id(Service, id),
         {:ok, service} <- Services.deactivate(service, consumer_id) do
      {:ok, %{service: service}}
    end
  end
end
