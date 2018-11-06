defmodule EHealth.GRPC.Server.Supervisor do
  use Supervisor

  alias GRPC.Server.Supervisor, as: GRPCSupervisor

  @moduledoc false

  def start_link(servers) do
    Supervisor.start_link(__MODULE__, servers, name: __MODULE__)
  end

  defdelegate init(servers), to: GRPCSupervisor
  defdelegate child_spec(servers, port, opts \\ []), to: GRPCSupervisor
end
