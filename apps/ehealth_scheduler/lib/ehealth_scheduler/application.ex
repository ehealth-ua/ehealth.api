defmodule EHealthScheduler.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias EHealthScheduler.Contracts.Terminator, as: ContractsTerminator
  alias EHealthScheduler.DeclarationRequests.Terminator, as: DeclarationRequestsTerminator
  alias EHealthScheduler.Worker

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Worker, []},
      {ContractsTerminator, []},
      Supervisor.child_spec({DeclarationRequestsTerminator, :declaration_request_terminator},
        id: :declaration_request_terminator
      ),
      Supervisor.child_spec({DeclarationRequestsTerminator, :declaration_request_cleaner},
        id: :declaration_request_cleaner
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EHealthScheduler.Supervisor]
    result = Supervisor.start_link(children, opts)
    Worker.create_jobs()
    result
  end
end
