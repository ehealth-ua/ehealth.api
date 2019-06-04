defmodule GraphQL.Resolvers.ServiceGroup do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2]
  import GraphQL.Filters.ServiceCatalog, only: [filter: 2]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_parent_with_connection: 4]

  alias Absinthe.Relay.Connection
  alias Core.Services
  alias Core.Services.ServiceGroup

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def list_service_groups(%{filter: filter, order_by: order_by} = args, _) do
    ServiceGroup
    |> filter(filter)
    |> order_by(^order_by)
    |> Connection.from_query(&@read_prm_repo.all/1, args)
  end

  def load_sub_groups(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :sub_groups)
  end

  def load_services(parent, args, resolution) do
    load_by_parent_with_connection(parent, args, resolution, :services)
  end

  def create(args, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, service_group} <- Services.create_service_group(args, consumer_id) do
      {:ok, %{service_group: service_group}}
    end
  end

  def deactivate(%{id: id}, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, service_group} <- Services.fetch_by_id(ServiceGroup, id),
         {:ok, service_group} <- Services.deactivate(service_group, consumer_id) do
      {:ok, %{service_group: service_group}}
    end
  end
end
