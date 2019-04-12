defmodule EdrValidationsConsumer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Kaffe.Consumer,
        start: {Kaffe.Consumer, :start_link, []}
      }
    ]

    Application.put_env(:kaffe, :consumer, Application.get_env(:edr_validations_consumer, :kaffe_consumer))

    opts = [strategy: :one_for_one, name: EdrValidationsConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
