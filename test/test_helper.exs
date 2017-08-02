{:ok, _} = Plug.Adapters.Cowboy.http EHealth.MockServer, [], port: Confex.fetch_env!(:ehealth, :mock)[:port]

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(EHealth.Repo, :manual)
