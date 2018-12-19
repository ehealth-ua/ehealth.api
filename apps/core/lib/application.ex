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
      {Core.EventManagerRepo, []},
      {Core.Validators.Cache, []}
    ]

    opts = [strategy: :one_for_one, name: Core.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
