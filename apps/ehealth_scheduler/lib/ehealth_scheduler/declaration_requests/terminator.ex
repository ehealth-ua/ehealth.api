defmodule EHealthScheduler.DeclarationRequests.Terminator do
  @moduledoc false

  use Confex, otp_app: :ehealth_scheduler
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

  defp expiration_options do
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

      %{term: term, unit: normalized_unit, user_id: user_id, limit: limit}
    else
      Logger.error(fn ->
        "Autoterminate declaration requests is not working, parameters invalid!"
      end)
    end
  end

  @impl true
  def handle_call({:update_state, state}, _, _) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_cast({:process_signed, caller}, state) do
    options = expiration_options()

    subselect_condition = fn query ->
      where(query, [dr], dr.status == ^DeclarationRequest.status(:signed) and not is_nil(dr.data))
    end

    rows_number =
      change_status_declaration_requests(
        subselect_condition,
        DeclarationRequest.status(:signed),
        options.term,
        options.unit,
        options.user_id,
        options.limit
      )

    if rows_number >= options.limit,
      do: GenServer.cast(:declaration_request_cleaner, {:process_signed, caller}),
      else: send(caller, :terminated_signed)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:process_expired, caller}, state) do
    options = expiration_options()

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
        options.term,
        options.unit,
        options.user_id,
        options.limit
      )

    if rows_number >= options.limit,
      do: GenServer.cast(:declaration_request_terminator, {:process_expired, caller}),
      else: send(caller, :terminated_expired)

    {:noreply, state}
  end

  @impl true
  def handle_cast(_signal, state) do
    {:noreply, state}
  end

  def clean_declaration_requests, do: GenServer.cast(:declaration_request_cleaner, {:process_signed, self()})
  def terminate_declaration_requests, do: GenServer.cast(:declaration_request_terminator, {:process_expired, self()})

  def change_status_declaration_requests(subselect_condition, status, term, unit, user_id, limit) do
    subselect_ids =
      DeclarationRequest
      |> select([dr], %{id: dr.id})
      |> where(
        [dr],
        dr.inserted_at < datetime_add(^NaiveDateTime.utc_now(), ^(-1 * String.to_integer(term)), ^unit)
      )
      |> subselect_condition.()
      |> order_by([dr], desc: :inserted_at)
      |> limit(^limit)

    {rows_updated, _} =
      DeclarationRequest
      |> join(:inner, [d], dr in subquery(subselect_ids), on: dr.id == d.id)
      |> update(
        [d],
        set: [
          status: ^status,
          data: nil,
          data_legal_entity_id: nil,
          data_employee_id: nil,
          data_start_date_year: nil,
          data_person_tax_id: nil,
          data_person_first_name: nil,
          data_person_last_name: nil,
          data_person_birth_date: nil,
          authentication_method_current: nil,
          printout_content: nil,
          updated_by: ^user_id,
          updated_at: ^NaiveDateTime.utc_now()
        ]
      )
      |> Repo.update_all([])

    rows_updated
  end
end
