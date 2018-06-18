defmodule EHealth.Unit.DivisionsTest do
  @moduledoc """
  Divisions api tests
  """

  use EHealth.Web.ConnCase, async: false
  alias EHealth.Divisions, as: API

  describe "Additional JSON objects validation: validate_json_objects/1" do
    setup _context do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_address_type)
      build_division()
    end

    defp build_division do
      division =
        build(:division)
        |> Map.from_struct()
        |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

      {:ok, division: division}
    end

    test "returns :ok for correct structure", %{division: division} do
      assert :ok = API.validate_json_objects(division)
    end

    test "returns :error for incorrect address type (not from Dictionary)", %{division: division} do
      address = build(:address, %{"type" => "NOT_IN_DICTIONARY"})
      bad_addresses = [address]
      bad_division = Map.put(division, "addresses", bad_addresses)

      assert {:error, _} = API.validate_json_objects(bad_division)
    end

    test "returns :error for duplicate address types", %{division: division} do
      res = build(:address, %{"type" => "RESIDENCE"})
      bad_division = Map.put(division, "addresses", [res, res])
      assert {:error, _} = API.validate_json_objects(bad_division)

      reg = build(:address, %{"type" => "REGISTRATION"})
      bad_division = Map.put(division, "addresses", [reg, reg])
      assert {:error, _} = API.validate_json_objects(bad_division)
    end

    test "returns :error for multiple phones of the same type", %{division: division} do
      incorrect_phones = [
        %{"number" => "+380503410870", "type" => "MOBILE"},
        %{"number" => "+380503410871", "type" => "MOBILE"}
      ]

      bad_division = Map.put(division, "phones", incorrect_phones)

      assert {:error, _} = API.validate_json_objects(bad_division)
    end
  end
end
