defmodule EHealth.DuplicatePersons.Signals do
  @moduledoc false

  use GenServer

  alias EHealth.API.MPI
  alias EHealth.DuplicatePersons.Cleanup
  alias EHealth.DuplicatePersons.CleanupTasks

  def start_link do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def deactivate do
    GenServer.call(__MODULE__, :deactivate)
  end

  def handle_call(:deactivate, _from, state) do
    {:ok, %{"data" => merge_candidates}} = MPI.get_merge_candidates(%{status: "NEW"})

    Enum.each merge_candidates, fn merge_candidate ->
      Task.Supervisor.start_child CleanupTasks, fn ->
        Cleanup.cleanup(merge_candidate["person_id"])
      end
    end

    {:reply, :ok, state}
  end
end
