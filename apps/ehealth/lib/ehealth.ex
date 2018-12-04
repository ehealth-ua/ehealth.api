defmodule EHealth do
  @moduledoc """
  This is an entry point of ehealth application.
  """

  use Application
  import Supervisor.Spec, warn: false

  alias Confex.Resolver
  alias EHealth.Scheduler
  alias EHealth.Web.Endpoint

  def start(_type, _args) do
    # Configure Logger severity at runtime
    configure_log_level()

    # Define workers and child supervisors to be supervised
    children = [
      supervisor(EHealth.Web.Endpoint, []),
      worker(
        EHealth.DeclarationRequests.Terminator,
        [:declaration_request_terminator],
        id: :declaration_request_terminator
      ),
      worker(EHealth.DeclarationRequests.Terminator, [:declaration_request_cleaner], id: :declaration_request_cleaner),
      worker(EHealth.Contracts.Terminator, []),
      worker(EHealth.Scheduler, []),
      {Cluster.Supervisor, [Application.get_env(:ehealth, :topologies), [name: EHealth.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: EHealth.Supervisor]
    result = Supervisor.start_link(children, opts)
    Scheduler.create_jobs()
    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Endpoint.config_change(changed, removed)
    :ok
  end

  # Configures Logger level via LOG_LEVEL environment variable.
  defp configure_log_level do
    case System.get_env("LOG_LEVEL") do
      nil ->
        :ok

      level when level in ["debug", "info", "warn", "error"] ->
        Logger.configure(level: String.to_atom(level))

      level ->
        raise ArgumentError,
              "LOG_LEVEL environment should have one of 'debug', 'info', 'warn', 'error' values," <>
                "got: #{inspect(level)}"
    end
  end

  # Loads configuration in `:init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def init(_key, config) do
    Resolver.resolve(config)
  end
end
