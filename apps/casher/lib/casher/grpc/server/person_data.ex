defmodule Casher.Grpc.Server.PersonData do
  @moduledoc false

  alias Casher.PersonData, as: CasherPersonData
  alias CasherProto.PersonDataRequest
  alias CasherProto.PersonDataResponse
  alias Ecto.UUID

  @spec person_data(PersonDataRequest.t(), GRPC.Server.Stream.t()) :: PersonDataResponse.t()
  def person_data(%PersonDataRequest{user_id: "", client_id: ""} = request, _) do
    with {:ok, _} <- UUID.cast(request.employee_id),
         {:ok, person_ids} <- CasherPersonData.get_and_update(Map.take(request, ~w(employee_id)a)) do
      PersonDataResponse.new(person_ids: person_ids)
    else
      _ ->
        PersonDataResponse.new()
    end
  end

  def person_data(%PersonDataRequest{employee_id: ""} = request, _) do
    with {:ok, _} <- UUID.cast(request.user_id),
         {:ok, _} <- UUID.cast(request.client_id),
         {:ok, person_ids} <- CasherPersonData.get_and_update(Map.take(request, ~w(user_id client_id)a)) do
      PersonDataResponse.new(person_ids: person_ids)
    else
      _ ->
        PersonDataResponse.new()
    end
  end

  def person_data(_, _), do: PersonDataResponse.new()
end
