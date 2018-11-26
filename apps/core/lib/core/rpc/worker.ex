defmodule Core.Rpc.Worker do
  @moduledoc false

  use Confex, otp_app: :core
  require Logger

  @behaviour Core.API.RPCWorkerBehaviour

  def run(basename, module, function, args, attempt \\ 0, skip_servers \\ []) do
    if attempt >= config()[:max_attempts] do
      {:error, :badrpc}
    else
      do_run(basename, module, function, args, attempt, skip_servers)
    end
  end

  defp do_run(basename, module, function, args, attempt, skip_servers) do
    servers =
      Node.list()
      |> Enum.filter(&String.starts_with?(to_string(&1), basename))
      |> Enum.filter(fn server -> server not in skip_servers end)

    case servers do
      # Invalid basename or all servers are down
      [] ->
        {:error, :badrpc}

      _ ->
        server = Enum.random(servers)

        case :rpc.call(server, module, function, args) do
          # try a different server
          {:badrpc, :nodedown} ->
            run(basename, module, function, args, attempt + 1, [server | skip_servers])

          {:badrpc, error} ->
            Logger.error(inspect(error))
            {:error, :badrpc}

          {:EXIT, error} ->
            Logger.error(inspect(error))
            {:error, :badrpc}

          response ->
            response
        end
    end
  end
end
