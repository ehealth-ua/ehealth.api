defmodule EHealth.Unit.Divisions.APITest do
  @moduledoc """
  Divisions api tests
  """

  import EHealth.SimpleFactory, only: [address: 1]

  use EHealth.Web.ConnCase, async: false
  alias EHealth.Divisions.API

  describe "Additional JSON objects validation: validate_json_objects/1" do
    setup _ do
      insert(:il, :dictionary_phone_type)
      insert(:il, :address_type)

      division =
        "test/data/division.json"
        |> File.read!()
        |> Poison.decode!()

      {:ok, division: division}
    end

    test "returns :ok for correct structure", %{division: division} do
      assert :ok = API.validate_json_objects(division)
    end

    test "returns :error for incorrect address type (not from Dictionary)", %{division: division} do
      bad_addresses = [address("NOT_IN_DICTIONARY")]
      bad_division = Map.put(division, "addresses", bad_addresses)

      assert {:error, _} = API.validate_json_objects(bad_division)
    end

    test "returns :error for duplicate adress types", %{division: division} do
      one = address("RESIDENCE")
      two = address("REGISTRATION")
      three = address("RESIDENCE")
      bad_division = Map.put(division, "addresses", [one, two, three])

      assert {:error, _} = API.validate_json_objects(bad_division)
    end

    test "returns :error for multiple phones of the same type", %{division: division} do
      incorrect_phones = [
        %{"number" => "+380503410870", "type" => "MOBILE"},
        %{"number" => "+380503410871", "type" => "MOBILE"}]
      bad_division = Map.put(division, "phones", incorrect_phones)

      assert {:error, _} = API.validate_json_objects(bad_division)
    end
  end
end
