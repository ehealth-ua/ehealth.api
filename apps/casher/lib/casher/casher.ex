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
    redis_config = Casher.Redis.config()

    Enum.map(0..(redis_config[:pool_size] - 1), fn connection_index ->
      worker(
        Redix,
        [
          [
            host: redis_config[:host],
            port: redis_config[:port],
            password: redis_config[:password],
            database: redis_config[:database],
            name: :"redis_#{connection_index}"
          ]
        ],
        id: {Redix, connection_index}
      )
    end)
  end
end
