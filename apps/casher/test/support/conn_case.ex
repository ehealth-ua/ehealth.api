defmodule Casher.Web.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import Casher.Router.Helpers
      import Casher.Web.ConnCase
      import Core.Factories

      # The default endpoint for testing
      @endpoint Casher.Web.Endpoint
    end
  end

  setup tags do
    Casher.Redis.flushdb()

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Core.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Core.PRMRepo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Core.EventManagerRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Core.PRMRepo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Core.EventManagerRepo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
