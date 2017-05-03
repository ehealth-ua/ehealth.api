{:ok, _} = Plug.Adapters.Cowboy.http EHealth.MockServer, [], port: Confex.get_map(:ehealth, :mock)[:port]

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(EHealth.Repo, :manual)
