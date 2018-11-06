defmodule Casher.Grpc.Server.PersonDataTest do
  @moduledoc false

  use Casher.Web.ConnCase, async: false
  alias Casher.Grpc.Server.PersonData
  alias CasherProto.PersonDataRequest
  alias CasherProto.PersonDataResponse
  alias Ecto.UUID
  alias GRPC.Server.Stream
  import Core.Factories
  import Mox

  describe "person_data/2" do
    test "invalid uuid" do
      assert %PersonDataResponse{person_ids: []} = PersonData.person_data(%PersonDataRequest{}, %Stream{})

      assert %PersonDataResponse{person_ids: []} =
               PersonData.person_data(%PersonDataRequest{employee_id: "invalid"}, %Stream{})

      assert %PersonDataResponse{person_ids: []} =
               PersonData.person_data(%PersonDataRequest{user_id: "invalid", client_id: "invalid"}, %Stream{})
    end

    test "success" do
      party1 = insert(:prm, :party, birth_date: ~D[2000-01-03])
      party2 = insert(:prm, :party, birth_date: ~D[2000-01-02])
      party_user = insert(:prm, :party_user, party: party1)
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, party: party1, legal_entity_id: legal_entity.id)
      insert(:prm, :employee, party: party2)
      person_id = UUID.generate()

      expect(OPSMock, :get_person_ids, fn _, _ ->
        {:ok, %{"data" => %{"person_ids" => [person_id]}}}
      end)

      assert %PersonDataResponse{person_ids: [^person_id]} =
               PersonData.person_data(
                 %PersonDataRequest{user_id: party_user.user_id, client_id: employee.legal_entity_id},
                 %Stream{}
               )
    end
  end
end
