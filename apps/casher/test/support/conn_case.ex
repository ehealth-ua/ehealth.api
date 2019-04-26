defmodule Casher.ConnCase do
  @moduledoc false

  use ExUnit.CaseTemplate
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      # Import conveniences for testing with connections
      import Casher.ConnCase
      import Core.Factories
    end
  end

  setup tags do
    Casher.Redis.flushdb()

    :ok = Sandbox.checkout(Core.Repo)
    :ok = Sandbox.checkout(Core.PRMRepo)

    unless tags[:async] do
      Sandbox.mode(Core.Repo, {:shared, self()})
      Sandbox.mode(Core.PRMRepo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
