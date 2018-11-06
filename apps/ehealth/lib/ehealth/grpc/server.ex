defmodule EHealth.Grpc.Server do
  @moduledoc false

  use GRPC.Server, service: EHealthGrpc.Service

  defdelegate party_user(request, stream), to: EHealth.Grpc.Server.PartyUsers
  defdelegate employees_speciality(request, stream), to: EHealth.Grpc.Server.Employees
end
