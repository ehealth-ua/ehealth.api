defmodule Core.Application do
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do
    children = [
      supervisor(Core.Repo, []),
      supervisor(Core.PRMRepo, []),
      supervisor(Core.FraudRepo, []),
      supervisor(Core.EventManagerRepo, []),
      worker(Core.Validators.Cache, [])
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
