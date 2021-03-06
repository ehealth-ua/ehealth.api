defmodule Core.Man.Client do
  @moduledoc false

  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]
  require Logger

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def render_template(id, data) do
    case @rpc_worker.run("man_api", Man.Rpc, :render_template, [id, atoms_to_strings(data)]) do
      {:ok, body} ->
        {:ok, body}

      nil ->
        Logger.error("Man template with id: `#{id}` not found")
        {:error, {:internal_error, "Remote server internal error"}}

      error ->
        Logger.error("Cannot render template with error: `#{inspect(error)}`")
        {:error, {:internal_error, "Remote server internal error"}}
    end
  end
end
