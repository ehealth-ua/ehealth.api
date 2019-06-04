defmodule EdrValidationsConsumer.Kafka.ConsumerTest do
  @moduledoc false

  use Core.ConnCase, async: false
  alias Core.LegalEntities.EdrData
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Ecto.UUID
  alias EdrValidationsConsumer.Kafka.Consumer

  describe "consume event" do
    test "edr data not found" do
      assert :ok = Consumer.consume(%{"id" => UUID.generate()})
    end

    test "edr timeout by id" do
      %{id: edr_data_id} = insert(:prm, :edr_data)
      expect_get_legal_entity_detailed_info({:error, :timeout})
      error_message = "timeout"

      assert capture_log(fn ->
               assert :ok = Consumer.consume(%{"id" => edr_data_id})
             end) =~ error_message
    end

    test "edr not found at edr api" do
      %{id: edr_data_id} = insert(:prm, :edr_data)
      error_message = "Legal entity not found"
      expect_get_legal_entity_detailed_info({:error, %{"status_code" => 404, "body" => error_message}})

      assert capture_log(fn ->
               assert :ok = Consumer.consume(%{"id" => edr_data_id})
             end) =~ error_message
    end

    test "edr api token expired" do
      %{id: edr_data_id} = insert(:prm, :edr_data)
      error_message = "{\"errors\":[{\"code\":2,\"message\":\"Invalid token.\"}]}"
      expect_get_legal_entity_detailed_info({:error, %{"status_code" => 404, "body" => error_message}})

      assert capture_log(fn ->
               assert :ok = Consumer.consume(%{"id" => edr_data_id})
             end) =~ inspect(error_message)
    end

    test "edr api page not found" do
      %{id: edr_data_id} = insert(:prm, :edr_data)
      error_message = "{\"errors\":[{\"code\":3,\"message\":\"Sorry, that page does not exist.\"}]}"
      expect_get_legal_entity_detailed_info({:error, %{"status_code" => 404, "body" => error_message}})

      assert capture_log(fn ->
               assert :ok = Consumer.consume(%{"id" => edr_data_id})
             end) =~ inspect(error_message)
    end

    test "invalid state" do
      legal_entities = [build(:legal_entity, nhs_verified: true)]
      %{id: edr_data_id} = insert(:prm, :edr_data, legal_entities: legal_entities)

      assert [%LegalEntity{nhs_verified: true}] = legal_entities
      expect_get_legal_entity_detailed_info({:ok, %{"state" => 0}})
      assert :ok = Consumer.consume(%{"id" => edr_data_id})

      [%LegalEntity{nhs_verified: false}] = PRMRepo.all(LegalEntity)
    end

    test "edr fields update" do
      %{id: edr_data_id} = insert(:prm, :edr_data)
      address = %{"parts" => %{"atu_code" => "12345678"}}
      name = "bar"
      public_name = "public"

      kveds = [
        %{
          "name" => "Видання іншого програмного забезпечення",
          "code" => "58.29",
          "is_primary" => false
        }
      ]

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "state" => 1,
           "address" => address,
           "names" => %{"name" => name, "display" => public_name},
           "activity_kinds" => kveds
         }}
      )

      assert :ok = Consumer.consume(%{"id" => edr_data_id})

      assert [%EdrData{name: ^name, public_name: ^public_name, kveds: ^kveds, registration_address: ^address}] =
               PRMRepo.all(EdrData)
    end
  end
end
