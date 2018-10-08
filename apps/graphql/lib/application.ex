defmodule GraphQL.Application do
  @moduledoc """
  This application provides GraphQL API for eHealth services.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(GraphQLWeb.Endpoint, [])
    ]

    opts = [strategy: :one_for_one, name: GraphQL.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    GraphQLWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
