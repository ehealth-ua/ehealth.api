defmodule EHealth.MedicationRequestRequestsTest do

  use EHealth.Web.ConnCase, async: true

  alias EHealth.MedicationRequestRequests, as: API

  describe "medication_request_requests" do
    alias EHealth.MedicationRequestRequest
    setup do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      division = insert(:prm, :division,
        id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
        legal_entity: legal_entity,
        is_active: true)
      insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )
      :ok
    end

    def medication_request_request_fixture do
      {:ok, medication_request_request} = API.create(test_request(), "7488a646-e31f-11e4-aace-600308960662",
                                                     "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      medication_request_request
    end

    test "list_medication_request_requests/0 returns all medication_request_requests" do
      medication_request_request = medication_request_request_fixture()
      assert API.list_medication_request_requests() == [medication_request_request]
    end

    test "get_medication_request_request!/1 returns the medication_request_request with given id" do
      medication_request_request = medication_request_request_fixture()
      assert API.get_medication_request_request!(medication_request_request.id) == medication_request_request
    end

    test "create/1 with valid data creates a medication_request_request" do
      assert {:ok, %MedicationRequestRequest{} = medication_request_request} =
              API.create(test_request(), "7488a646-e31f-11e4-aace-600308960662", "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      assert medication_request_request.data == %EHealth.MedicationRequestRequest.EmbeddedData{
             created_at: ~D[2020-09-22],
             dispense_valid_from: ~D[2017-08-17], dispense_valid_to: ~D[2017-09-16],
             division_id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", employee_id: "7488a646-e31f-11e4-aace-600308960662",
             ended_at: ~D[2020-10-22], medication_id: "1349a693-4db1-4a3f-9ac6-8c2f9e541982",
             medication_qty: 10, person_id: "585044f5-1272-4bca-8d41-8440eefe7d26",
             started_at: ~D[2020-09-22],
             legal_entity_id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552"}
      assert medication_request_request.inserted_by == "7488a646-e31f-11e4-aace-600308960662"
      assert medication_request_request.status == "NEW"
      assert medication_request_request.updated_by == "7488a646-e31f-11e4-aace-600308960662"
    end

    test "create/1 with invalid data returns error changeset" do
      test_data =
        test_request()
        |> Map.put("division_id", Ecto.UUID.generate())
      assert {:error, %Ecto.Changeset{}} = API.create(test_data,
                                                      "7488a646-e31f-11e4-aace-600308960662",
                                                      "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
    end
  end

  def test_request do
    "test/data/medication_request_request/medication_request_request.json"
    |> File.read!()
    |> Poison.decode!
  end
end
