defmodule EHealth.DeclarationRequest.Terminator do
  @moduledoc """
    Process responsible for termination declaration requests which achieved their end_date
    Process runs once per day, in the night from 0 to 4 UTC
  """

  use GenServer

  import EHealth.DeclarationRequest.API, only: [terminate_declaration_requests: 0]

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
    terminate_declaration_requests()

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
