defmodule EHealth.Unit.LegalEntity.ValidatorTest do
  @moduledoc """
  Legal entity validations tests
  """

  use EHealth.Web.ConnCase, async: false

  alias EHealth.LegalEntity.Validator

  describe "Additional JSON objects validation: validate_json_objects/1" do
    setup _ do
      insert(:il, :dictionary_phone_type)
      insert(:il, :address_type)

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
      bad_addresses = [get_address("NOT_IN_DICTIONARY")]
      bad_legal_entity = Map.put(legal_entity, "addresses", bad_addresses)

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "returns :error for duplicate adress types", %{legal_entity: legal_entity} do
      one = get_address("RESIDENCE")
      two = get_address("REGISTRATION")
      three = get_address("RESIDENCE")
      bad_legal_entity = Map.put(legal_entity, "addresses", [one, two, three])

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end

    test "returns :error for multiple phones of the same type", %{legal_entity: legal_entity} do
      incorrect_phones = [
        %{"number" => "+380503410870", "type" => "MOBILE"},
        %{"number" => "+380503410871", "type" => "MOBILE"}]
      bad_legal_entity = Map.put(legal_entity, "phones", incorrect_phones)

      assert {:error, _} = Validator.validate_json_objects(bad_legal_entity)
    end
  end

  defp get_address(type) when type in ["RESIDENCE", "REGISTRATION", "NOT_IN_DICTIONARY"] do
    %{"apartment" => "23", "area" => "Житомирська",
    "building" => "15-В", "country" => "UA",
    "region" => "Бердичівський", "settlement" => "Київ",
    "settlement_id" => "dsdafdf", "settlement_type" => "CITY",
    "street" => "вул. Ніжинська", "type" => type,
    "zip" => "02090"}
  end
end
