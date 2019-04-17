defmodule EdrValidationsConsumer.Kafka.ConsumerTest do
  @moduledoc false

  use Core.ConnCase, async: false
  alias Core.LegalEntities.EdrVerification
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Ecto.UUID
  alias EdrValidationsConsumer.Kafka.Consumer

  @status_verified EdrVerification.status(:verified)
  @status_error EdrVerification.status(:error)

  describe "consume event" do
    test "legal entity not found" do
      legal_entity_id = UUID.generate()
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 error_message: "Legal entity not found",
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "invalid edrpou" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity, edrpou: "invalid")
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 error_message: "Invalid EDRPOU (DRFO)",
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "edr timeout by code" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      expect_edr_by_code({:error, :timeout})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 status_code: 504,
                 edr_status: @status_error,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "edr timeout by passport" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity, edrpou: "НЕ111111")
      expect_edr_by_passport({:error, :timeout})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 status_code: 504,
                 edr_status: @status_error,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "legal entity not found at edr api" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      error_message = "Legal entity not found"
      expect_edr_by_code({:error, %{"status_code" => 404, "body" => error_message}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 error_message: ^error_message,
                 status_code: 404,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "edr api token expired" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      error_message = "{\"errors\":[{\"code\":2,\"message\":\"Invalid token.\"}]}"
      expect_edr_by_code({:error, %{"status_code" => 401, "body" => error_message}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 error_message: ^error_message,
                 status_code: 401,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "edr api page not found" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      error_message = "{\"errors\":[{\"code\":3,\"message\":\"Sorry, that page does not exist.\"}]}"
      expect_edr_by_code({:error, %{"status_code" => 404, "body" => error_message}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 error_message: ^error_message,
                 status_code: 404,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "failed to get settlement" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      expect_edr_by_code({:ok, %{}})
      expect_settlement_by_id(nil)
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 edr_data: %{
                   "address" => nil,
                   "legal_form" => nil,
                   "name" => nil
                 },
                 error_message: "Invalid settlement",
                 status_code: 200,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)
    end

    test "invalid state" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      expect_edr_by_code({:ok, %{"state" => 0}})
      expect_settlement_by_id({:ok, %{}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 edr_data: %{
                   "address" => nil,
                   "legal_form" => nil,
                   "name" => nil
                 },
                 legal_entity_data: %{
                   "address" => nil,
                   "legal_form" => "240",
                   "name" => "Клініка Борис"
                 },
                 edr_state: 0,
                 edr_status: @status_error,
                 status_code: 200,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)

      [%LegalEntity{edr_verified: false}] = PRMRepo.all(LegalEntity)
    end

    test "edr fields doesn't match" do
      %{id: legal_entity_id} = insert(:prm, :legal_entity)

      expect_edr_by_code(
        {:ok, %{"state" => 1, "address" => %{"parts" => %{"atu_code" => "12345678"}}, "name" => "foo"}}
      )

      expect_settlement_by_id({:ok, %{koatuu: "12345600"}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 edr_data: %{
                   "address" => "12345678",
                   "legal_form" => nil,
                   "name" => nil
                 },
                 legal_entity_data: %{
                   "address" => "12345600",
                   "legal_form" => "240",
                   "name" => "Клініка Борис"
                 },
                 edr_state: 1,
                 edr_status: @status_error,
                 status_code: 200,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)

      [%LegalEntity{edr_verified: false}] = PRMRepo.all(LegalEntity)
    end

    test "success verification" do
      legal_entity = insert(:prm, :legal_entity)
      legal_entity_id = legal_entity.id
      legal_form = legal_entity.legal_form
      name = legal_entity.name

      expect_edr_by_code(
        {:ok,
         %{
           "state" => 1,
           "address" => %{"parts" => %{"atu_code" => "12345678"}},
           "names" => %{"display" => name},
           "olf_code" => legal_form
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "12345600"}})
      assert :ok = Consumer.consume(%{"legal_entity_id" => legal_entity_id})

      assert [
               %EdrVerification{
                 edr_data: %{
                   "address" => "12345678",
                   "legal_form" => ^legal_form,
                   "name" => ^name
                 },
                 legal_entity_data: %{
                   "address" => "12345600",
                   "legal_form" => ^legal_form,
                   "name" => ^name
                 },
                 edr_state: 1,
                 edr_status: @status_verified,
                 status_code: 200,
                 legal_entity_id: ^legal_entity_id
               }
             ] = PRMRepo.all(EdrVerification)

      [%LegalEntity{edr_verified: true}] = PRMRepo.all(LegalEntity)
    end
  end
end
