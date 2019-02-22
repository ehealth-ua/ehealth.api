defmodule DeactivateLegalEntityConsumer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      %{
        id: Kaffe.Consumer,
        start: {Kaffe.Consumer, :start_link, []}
      }
    ]

    Application.put_env(:kaffe, :consumer, Application.get_env(:deactivate_legal_entity_consumer, :kaffe_consumer))

    opts = [strategy: :one_for_one, name: DeactivateLegalEntityConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
