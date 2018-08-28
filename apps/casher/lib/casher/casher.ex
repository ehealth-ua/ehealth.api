defmodule Casher do
  @moduledoc false

  use Application
  import Supervisor.Spec

  @spec start(Application.start_type(), list) :: Supervisor.on_start()
  def start(_type, _args) do
    children =
      Enum.concat(redis_workers(), [
        supervisor(Casher.Web.Endpoint, [])
      ])

    opts = [strategy: :one_for_one, name: Casher.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @spec redis_workers :: list
  def redis_workers do
    pool_size = Confex.fetch_env!(:casher, :redis_pool_size)
    redis_config = Confex.fetch_env!(:casher, Redix)

    Enum.map(0..(pool_size - 1), fn connection_index ->
      args = [redis_config, [name: :"redis_#{connection_index}"]]

      Supervisor.child_spec({Redix, args}, id: {Redix, connection_index})
    end)
  end
end
