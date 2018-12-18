defmodule Casher.Web.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

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

    :ok = Sandbox.checkout(Core.ReadRepo)
    :ok = Sandbox.checkout(Core.Repo)
    :ok = Sandbox.checkout(Core.PRMRepo)
    :ok = Sandbox.checkout(Core.EventManagerRepo)

    unless tags[:async] do
      Sandbox.mode(Core.Repo, {:shared, self()})
      Sandbox.mode(Core.PRMRepo, {:shared, self()})
      Sandbox.mode(Core.EventManagerRepo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
