defmodule EHealth.Grpc.Protobuf.Server.Employees do
  @moduledoc false

  alias Core.Employees.Employee
  alias Core.PRMRepo
  alias Ecto.UUID
  alias EHealthProto.EmployeesRequest
  alias EHealthProto.EmployeesResponse
  alias EHealthProto.EmployeesResponse.Employee, as: E
  alias EHealthProto.EmployeesResponse.Speciality
  import Ecto.Query

  @spec employees_speciality(EmployeesRequest.t(), GRPC.Server.Stream.t()) :: EmployeesResponse.t()
  def employees_speciality(%EmployeesRequest{party_id: party_id, legal_entity_id: legal_entity_id}, _) do
    query = fn ->
      Employee
      |> select([e], e.speciality)
      |> where([e], e.party_id == ^party_id)
      |> where([e], e.legal_entity_id == ^legal_entity_id)
    end

    with {:ok, _} <- UUID.cast(party_id),
         {:ok, _} <- UUID.cast(legal_entity_id),
         employees <- PRMRepo.all(query.()) do
      EmployeesResponse.new(
        employees:
          Enum.map(employees, fn employee ->
            %E{speciality: Speciality.new(speciality: employee["speciality"])}
          end)
      )
    else
      _ ->
        EmployeesResponse.new()
    end
  end
end
