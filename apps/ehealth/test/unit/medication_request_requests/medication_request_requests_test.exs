defmodule EHealth.MedicationRequestRequestsTest do
  use EHealth.Web.ConnCase, async: true

  alias EHealth.MedicationRequestRequests, as: API

  describe "medication_request_requests" do
    setup do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      division =
        insert(
          :prm,
          :division,
          id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b",
          legal_entity: legal_entity,
          is_active: true
        )

      insert(
        :prm,
        :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )

      :ok
    end

    def medication_request_request_fixture do
      {:ok, medication_request_request} =
        API.create(test_request(), "7488a646-e31f-11e4-aace-600308960662", "7cc91a5d-c02f-41e9-b571-1ea4f2375552")

      medication_request_request
    end
  end

  def test_request do
    "test/data/medication_request_request/medication_request_request.json"
    |> File.read!()
    |> Jason.decode!()
  end
end
