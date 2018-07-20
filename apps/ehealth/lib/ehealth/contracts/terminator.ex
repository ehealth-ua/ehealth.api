defmodule EHealth.Contracts.Terminator do
  @moduledoc false

  import Ecto.Query
  use Confex, otp_app: :ehealth
  use GenServer
  alias Ecto.UUID
  alias EHealth.Contracts.Contract
  alias EHealth.PRMRepo
  require Logger

  @server __MODULE__

  def start_link do
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
    {:ok, user_id} = UUID.dump(Confex.fetch_env!(:ehealth, :system_user))
    limit = config()[:termination_batch_size]
    %{limit: limit, user_id: user_id}
  end

  def terminate_contracts do
    GenServer.call(@server, {:update_state, state_options()})
    GenServer.cast(@server, {:process_terminate, self()})
  end

  defp terminate_contracts(user_id, limit) do
    terminated = Contract.status(:terminated)

    subselect_ids =
      Contract
      |> select([c], %{id: c.id})
      |> where([c], c.end_date < ^NaiveDateTime.utc_now() and c.status != ^terminated)
      |> limit(^limit)

    {rows_updated, _} =
      Contract
      |> join(:inner, [c], cr in subquery(subselect_ids), c.id == cr.id)
      |> update(
        [c],
        set: [
          status: ^terminated,
          status_reason: "auto_expired",
          updated_by: ^user_id,
          updated_at: ^NaiveDateTime.utc_now()
        ]
      )
      |> PRMRepo.update_all([])

    rows_updated
  end
end
