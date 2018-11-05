defmodule EHealth.Integration.Grpc.Server.PartyUsersTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.Grpc.Protobuf.Server.PartyUsers
  alias EHealthProto.PartyUserRequest
  alias EHealthProto.PartyUserResponse
  alias EHealthProto.PartyUserResponse.PartyUser
  alias GRPC.Server.Stream

  describe "party_user/2" do
    test "invalid uuid" do
      assert %PartyUserResponse{party_user: nil} = PartyUsers.party_user(%PartyUserRequest{}, %Stream{})

      assert %PartyUserResponse{party_user: nil} =
               PartyUsers.party_user(%PartyUserRequest{user_id: "invalid"}, %Stream{})
    end

    test "success" do
      party_user = insert(:prm, :party_user)
      party_id = party_user.party_id
      insert(:prm, :party_user)

      assert %PartyUserResponse{party_user: %PartyUser{party_id: ^party_id}} =
               PartyUsers.party_user(%PartyUserRequest{user_id: party_user.user_id}, %Stream{})
    end
  end
end
