defmodule GraphQL.Phase.RequestID do
  @moduledoc """
  Adds request_id in extensions
  """

  use Absinthe.Phase

  require Logger

  def run(bp, _options \\ []) do
    request_id = Logger.metadata()[:request_id]
    extensions = %{requestId: request_id}
    result = Map.put(bp.result, :extensions, extensions)

    {:ok, %{bp | result: result}}
  end
end
