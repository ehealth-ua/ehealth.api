defmodule Core.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Core.ReadRepo, []},
      {Core.Repo, []},
      {Core.ReadPRMRepo, []},
      {Core.PRMRepo, []},
      {Core.FraudRepo, []},
      {Core.Validators.Cache, []}
    ]

    children =
      if Application.get_env(:core, :env) == :prod do
        children ++
          [
            {Cluster.Supervisor, [Application.get_env(:core, :topologies), [name: Core.ClusterSupervisor]]}
          ]
      else
        children
      end

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
