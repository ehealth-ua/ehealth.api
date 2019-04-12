defmodule EHealth do
  @moduledoc """
  This is an entry point of ehealth application.
  """

  use Application
  alias EHealth.Web.Endpoint

  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      {Endpoint, []}
    ]

    opts = [strategy: :one_for_one, name: EHealth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
