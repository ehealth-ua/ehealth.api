defmodule Core.Rpc.Error do
  defexception message: "Invalid RPC response"
end

defimpl Plug.Exception, for: Core.Rpc.Error do
  def status(_), do: 500
end
