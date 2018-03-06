{:ok, _} =
  Plug.Adapters.Cowboy.http(
    EHealth.MockServer,
    [],
    port: Confex.fetch_env!(:ehealth, :mock)[:port]
  )

{:ok, _} = Application.ensure_all_started(:ex_machina)

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(EHealth.Repo, :manual)
# Ecto.Adapters.SQL.Sandbox.mode(EHealth.PRMRepo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(EHealth.EventManagerRepo, :manual)

Mox.defmock(ManMock, for: EHealth.API.ManBehaviour)
Mox.defmock(MithrilMock, for: EHealth.API.MithrilBehaviour)
