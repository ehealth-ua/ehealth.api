defmodule EHealthScheduler.Contracts.Terminator do
  @moduledoc false

  use Confex, otp_app: :ehealth_scheduler
  use GenServer

  import Ecto.Query

  alias Core.Contracts.CapitationContract
  alias Core.EventManager
  alias Core.PRMRepo

  require Logger

  @server __MODULE__

  def start_link(_) do
    GenServer.start_link(@server, %{}, name: @server)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:update_state, state}, _, _) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(
        {:process_terminate, caller},
        %{user_id: user_id, limit: limit} = state
      ) do
    rows_number = terminate_contracts(user_id, limit)

    if rows_number >= limit do
      GenServer.cast(@server, {:process_terminate, caller})
    else
      send(caller, :terminated_contracts)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(_, state), do: {:noreply, state}

  defp state_options do
    user_id = Confex.fetch_env!(:core, :system_user)
    limit = config()[:termination_batch_size]
    %{limit: limit, user_id: user_id}
  end

  def terminate_contracts do
    GenServer.call(@server, {:update_state, state_options()})
    GenServer.cast(@server, {:process_terminate, self()})
  end

  defp terminate_contracts(user_id, limit) do
    terminated = CapitationContract.status(:terminated)

    subselect_ids =
      CapitationContract
      |> select([c], %{id: c.id})
      |> where([c], c.end_date < ^NaiveDateTime.utc_now() and c.status != ^terminated)
      |> limit(^limit)

    {rows_updated, contracts} =
      CapitationContract
      |> join(:inner, [c], cr in subquery(subselect_ids), c.id == cr.id)
      |> PRMRepo.update_all(
        [
          set: [
            status: terminated,
            status_reason: "AUTO_EXPIRED",
            updated_by: user_id,
            updated_at: NaiveDateTime.utc_now()
          ]
        ],
        returning: [:id]
      )

    log_status_updates(contracts, terminated, user_id)

    rows_updated
  end

  def log_status_updates(contracts, new_status, user_id) do
    Enum.map(contracts, fn contract ->
      with {:ok, event} <- EventManager.publish_change_status(contract, new_status, user_id) do
        event
      end
    end)
  end
end
