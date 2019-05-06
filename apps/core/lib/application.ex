defmodule Core.Application do
  @moduledoc false

  use Application
  alias Core.TelemetryHandler.FraudRepoHandler
  alias Core.TelemetryHandler.PRMRepoHandler
  alias Core.TelemetryHandler.ReadPRMRepoHandler
  alias Core.TelemetryHandler.ReadRepoHandler
  alias Core.TelemetryHandler.RepoHandler

  def start(_type, _args) do
    :telemetry.attach("log-handler", [:core, :repo, :query], &RepoHandler.handle_event/4, nil)
    :telemetry.attach("log-read-handler", [:core, :read_repo, :query], &ReadRepoHandler.handle_event/4, nil)
    :telemetry.attach("log-prm-repo-handler", [:core, :prm_repo, :query], &PRMRepoHandler.handle_event/4, nil)

    :telemetry.attach(
      "log-read-prm-repo-handler",
      [:core, :read_prm_repo, :query],
      &ReadPRMRepoHandler.handle_event/4,
      nil
    )

    :telemetry.attach("log-fraud-repo-handler", [:core, :fraud_repo, :query], &FraudRepoHandler.handle_event/4, nil)

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
