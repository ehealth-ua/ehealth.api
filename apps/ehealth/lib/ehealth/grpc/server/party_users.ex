defmodule EHealth.Grpc.Server.PartyUsers do
  @moduledoc false

  alias Core.Parties
  alias Core.Parties.Party
  alias Ecto.UUID
  alias EHealthProto.PartyUserRequest
  alias EHealthProto.PartyUserResponse
  alias EHealthProto.PartyUserResponse.PartyUser

  @spec party_user(PartyUserRequest.t(), GRPS.Server.Stream.t()) :: PartyUserResponse.t()
  def party_user(%PartyUserRequest{user_id: user_id}, _) do
    with {:ok, _} <- UUID.cast(user_id),
         %Party{} = party <- Parties.get_by_user_id(user_id) do
      PartyUserResponse.new(party_user: %PartyUser{party_id: party.id})
    else
      _ ->
        PartyUserResponse.new()
    end
  end
end
