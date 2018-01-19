defmodule EHealth do
  @moduledoc """
  This is an entry point of ehealth application.
  """

  use Application
  alias EHealth.Web.Endpoint
  alias Confex.Resolver
  alias EHealth.Scheduler
  import Supervisor.Spec, warn: false

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Configure Logger severity at runtime
    configure_log_level()

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(EHealth.DuplicatePersons, []),
      supervisor(EHealth.Repo, []),
      supervisor(EHealth.PRMRepo, []),
      supervisor(EHealth.FraudRepo, []),
      supervisor(EHealth.EventManagerRepo, []),
      # Start the endpoint when the application starts
      supervisor(EHealth.Web.Endpoint, []),
      worker(EHealth.Scheduler, [])
      # Starts a worker by calling: EHealth.Worker.start_link(arg1, arg2, arg3)
      # worker(EHealth.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
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
