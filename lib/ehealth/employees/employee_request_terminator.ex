defmodule EHealth.EmployeeRequest.Terminator do
  @moduledoc """
    Process responsible for termination employee requests
    Process runs once per day, in the night from 0 to 4 UTC
  """

  use GenServer

  import EHealth.EmployeeRequests, only: [update_all: 2]
  import Ecto.Query

  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.GlobalParameters

  # Client API

  @config Confex.get_env(:ehealth, __MODULE__)

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Server API

  def init(_) do
    now = DateTime.to_time(DateTime.utc_now)
    {from, _to} = @config[:utc_interval]
    ms = if validate_time(now.hour, @config[:utc_interval]),
      do: @config[:frequency],
      else: abs(from - now.hour) * 60 * 60 * 1000

    {:ok, schedule_next_run(ms)}
  end

  def handle_cast({:terminate, ms}, _) do
    parameters = GlobalParameters.get_values()

    is_valid? =
      Enum.all?(~w(employee_request_expiration employee_request_term_unit), fn param ->
        Map.has_key? parameters, param
      end)

    if is_valid? do
      %{
        "employee_request_expiration" => term,
        "employee_request_term_unit" => unit,
      } = parameters

      normalized_unit =
        unit
        |> String.downcase
        |> String.replace_trailing("s", "")

      statuses = Enum.map(~w(approved rejected expired)a, &Request.status/1)
      query =
        Request
        |> where([er], not er.status in ^statuses)
        |> where([er], fragment("?::date < now()::date", datetime_add(er.inserted_at, ^term, ^normalized_unit)))
      update_all(query, [status: Request.status(:expired)])
    end

    {:noreply, schedule_next_run(ms)}
  end

  def terminate_msg(ms), do: {:"$gen_cast", {:terminate, ms}}

  defp validate_time(hour, {from, to}), do: hour >= from && hour <= to

  defp schedule_next_run(ms) do
    unless Application.get_env(:ehealth, :env) == :test do
      Process.send_after(self(), terminate_msg(ms), ms)
    end
  end
end
