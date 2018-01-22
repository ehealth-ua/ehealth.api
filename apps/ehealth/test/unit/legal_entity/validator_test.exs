defmodule EHealth.Unit.LegalEntity.ValidatorTest do
  @moduledoc """
  Legal entity validations tests
  """

  use EHealth.Web.ConnCase, async: false

  alias EHealth.LegalEntities.Validator
  import EHealth.SimpleFactory, only: [address: 1]

  describe "Additional JSON objects validation: validate_json_objects/1" do
    setup _ do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_address_type)
      insert(:il, :dictionary_document_type)

      legal_entity =
        "test/data/legal_entity.json"
        |> File.read!()
        |> Poison.decode!()

      {:ok, legal_entity: legal_entity}
    end

    test "returns :ok for correct structure", %{legal_entity: legal_entity} do
      assert :ok = Validator.validate_json_objects(legal_entity)
    end

    test "returns :error for incorrect address type (not from Dictionary)", %{legal_entity: legal_entity} do
      bad_addresses = [address("NOT_IN_DICTIONARY")]
      bad_legal_entity = Map.put(legal_entity, "addresses", bad_addresses)

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "returns :error for duplicate adress types", %{legal_entity: legal_entity} do
      one = address("RESIDENCE")
      two = address("REGISTRATION")
      three = address("RESIDENCE")
      bad_legal_entity = Map.put(legal_entity, "addresses", [one, two, three])

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "returns :error for multiple phones of the same type", %{legal_entity: legal_entity} do
      mob = %{"number" => "+380503410870", "type" => "MOBILE"}
      bad_legal_entity = Map.put(legal_entity, "phones", [mob, mob])

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "return :error for incorrect owner phones", %{legal_entity: legal_entity} do
      mob = %{"number" => "+380503410870", "type" => "MOBILE"}
      bad_legal_entity = put_in(legal_entity, ["owner", "phones"], [mob, mob])

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "return :error for incorrect owner documents", %{legal_entity: legal_entity} do
      passp = %{"type" => "PASSPORT", "number" => "120518"}
      bad_legal_entity = put_in(legal_entity, ["owner", "documents"], [passp, passp])

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end
  end
end
