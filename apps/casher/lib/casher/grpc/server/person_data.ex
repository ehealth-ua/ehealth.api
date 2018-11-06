defmodule Casher.Grpc.Server.PersonData do
  @moduledoc false

  alias Casher.PersonData, as: CasherPersonData
  alias CasherProto.PersonDataRequest
  alias CasherProto.PersonDataResponse
  alias Ecto.UUID

  @spec person_data(PersonDataRequest.t(), GRPC.Server.Stream.t()) :: PersonDataResponse.t()
  def person_data(%PersonDataRequest{employee_id: employee_id} = request, _) when not is_nil(employee_id) do
    with {:ok, _} <- UUID.cast(employee_id),
         {:ok, person_ids} <- CasherPersonData.get_and_update(request) do
      PersonDataResponse.new(person_ids: person_ids)
    else
      _ ->
        PersonDataResponse.new()
    end
  end

  def person_data(%PersonDataRequest{user_id: user_id, client_id: client_id} = request, _)
      when not is_nil(user_id) and not is_nil(client_id) do
    with {:ok, _} <- UUID.cast(user_id),
         {:ok, _} <- UUID.cast(client_id),
         {:ok, person_ids} <- CasherPersonData.get_and_update(request) do
      PersonDataResponse.new(person_ids: person_ids)
    else
      _ ->
        PersonDataResponse.new()
    end
  end

  def person_data(_, _), do: PersonDataResponse.new()
end
