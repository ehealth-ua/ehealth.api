defmodule Casher.Grpc.Server do
  @moduledoc false

  use GRPC.Server, service: CasherGrpc.Service

  defdelegate person_data(request, stream), to: Casher.Grpc.Server.PersonData
end
