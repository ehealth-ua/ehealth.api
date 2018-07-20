defmodule EHealth.DuplicatePersons do
  @moduledoc false

  use Supervisor

  alias EHealth.DuplicatePersons.CleanupTasks
  alias EHealth.DuplicatePersons.Signals

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(Signals, []),
      supervisor(Task.Supervisor, [[name: CleanupTasks]], restart: :permanent)
    ]

    supervise(children, strategy: :one_for_one)
  end
end
