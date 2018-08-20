defmodule EHealth.DeclarationRequests.Terminator do
  @moduledoc false

  use Confex, otp_app: :ehealth
  use GenServer

  import Ecto.Query

  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.GlobalParameters
  alias Core.Repo
  alias Ecto.UUID

  require Logger

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def state_options do
    parameters = GlobalParameters.get_values()

    is_valid? =
      Enum.all?(~w(declaration_request_expiration declaration_request_term_unit), fn param ->
        Map.has_key?(parameters, param)
      end)

    if is_valid? do
      %{
        "declaration_request_expiration" => term,
        "declaration_request_term_unit" => unit
      } = parameters

      normalized_unit =
        unit
        |> String.downcase()
        |> String.replace_trailing("s", "")

      {:ok, user_id} = UUID.dump(Confex.fetch_env!(:core, :system_user))
      limit = config()[:termination_batch_size]

      %{term: term, normalized_unit: normalized_unit, user_id: user_id, limit: limit}
    else
      Logger.error(fn -> "Autoterminate declaration requests is not working, parameters invalid!" end)
    end
  end

  @impl true
  def handle_call({:update_state, state}, _, _) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast(
        {:process_signed, caller},
        %{term: term, normalized_unit: unit, user_id: user_id, limit: limit} = state
      ) do
    subselect_condition = fn query ->
      where(
        query,
        [dr],
        dr.status == ^DeclarationRequest.status(:signed) and not is_nil(dr.data)
      )
    end

    rows_number =
      change_status_declaration_requests(
        subselect_condition,
        DeclarationRequest.status(:signed),
        term,
        unit,
        user_id,
        limit
      )

    if rows_number >= limit do
      GenServer.cast(:declaration_request_cleaner, {:process_signed, caller})
    else
      send(caller, :terminated_signed)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:process_expired, caller},
        %{term: term, normalized_unit: unit, user_id: user_id, limit: limit} = state
      ) do
    subselect_condition = fn query ->
      where(
        query,
        [dr],
        dr.status != ^DeclarationRequest.status(:signed) and dr.status != ^DeclarationRequest.status(:expired)
      )
    end

    rows_number =
      change_status_declaration_requests(
        subselect_condition,
        DeclarationRequest.status(:expired),
        term,
        unit,
        user_id,
        limit
      )

    if rows_number >= limit do
      GenServer.cast(:declaration_request_terminator, {:process_expired, caller})
    else
      send(caller, :terminated_expired)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast(_signal, state) do
    {:noreply, state}
  end

  def terminate_declaration_requests do
    state = state_options()

    Enum.each(
      [:declaration_request_terminator, :declaration_request_cleaner],
      &(:ok = GenServer.call(&1, {:update_state, state}))
    )

    GenServer.cast(:declaration_request_cleaner, {:process_signed, self()})
    GenServer.cast(:declaration_request_terminator, {:process_expired, self()})
  end

  def change_status_declaration_requests(subselect_condition, status, term, unit, user_id, limit) do
    subselect_ids =
      DeclarationRequest
      |> select([dr], %{id: dr.id})
      |> where(
        [dr],
        dr.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-1 * String.to_integer(term)), ^unit)
      )
      |> subselect_condition.()
      |> limit(^limit)

    {rows_updated, _} =
      DeclarationRequest
      |> join(:inner, [d], dr in subquery(subselect_ids), dr.id == d.id)
      |> update(
        [d],
        set: [
          status: ^status,
          data: nil,
          authentication_method_current: nil,
          documents: nil,
          printout_content: nil,
          updated_by: ^user_id,
          updated_at: ^NaiveDateTime.utc_now()
        ]
      )
      |> Repo.update_all([])

    rows_updated
  end
end
