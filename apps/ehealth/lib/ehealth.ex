defmodule EHealth do
  @moduledoc """
  This is an entry point of ehealth application.
  """

  use Application
  alias EHealth.Web.Endpoint

  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      {EHealth.Web.Endpoint, []}
    ]

    children =
      if Application.get_env(:ehealth, :env) == :prod do
        children ++
          [
            {Cluster.Supervisor, [Application.get_env(:ehealth, :topologies), [name: EHealth.ClusterSupervisor]]}
          ]
      else
        children
      end

    opts = [strategy: :one_for_one, name: EHealth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
