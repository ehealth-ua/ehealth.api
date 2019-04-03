{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(Core.PRMRepo, :manual)
