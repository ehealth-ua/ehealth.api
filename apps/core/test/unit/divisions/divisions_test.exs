defmodule Core.Unit.DivisionsTest do
  @moduledoc """
  Divisions api tests
  """

  use Core.ConnCase, async: false

  alias Core.Divisions, as: API
  alias Core.ValidationError

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

      addresses =
        Enum.map(division["addresses"], fn x ->
          x
          |> Map.from_struct()
          |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)
        end)

      division = Map.put(division, "addresses", addresses)
      {:ok, division: division}
    end

    test "returns :ok for correct structure", %{division: division} do
      assert :ok = API.validate_json_objects(division)
    end

    test "returns :error for duplicate address types", %{division: division} do
      res = build(:address, %{"type" => "RESIDENCE"})
      bad_division = Map.put(division, "addresses", [res, res])

      assert %ValidationError{
               description: "No duplicate values.",
               params: ["RESIDENCE"],
               path: "$.addresses.[1].type",
               rule: :invalid
             } = API.validate_json_objects(bad_division)

      reg = build(:address, %{"type" => "REGISTRATION"})
      bad_division = Map.put(division, "addresses", [reg, reg])

      assert %ValidationError{
               description: "No duplicate values.",
               params: ["REGISTRATION"],
               path: "$.addresses.[1].type",
               rule: :invalid
             } = API.validate_json_objects(bad_division)
    end

    test "returns :error for multiple phones of the same type", %{division: division} do
      incorrect_phones = [
        %{"number" => "+380503410870", "type" => "MOBILE"},
        %{"number" => "+380503410871", "type" => "MOBILE"}
      ]

      bad_division = Map.put(division, "phones", incorrect_phones)

      assert %ValidationError{
               description: "No duplicate values.",
               params: ["MOBILE"],
               path: "$.phones.[1].type",
               rule: :invalid
             } = API.validate_json_objects(bad_division)
    end
  end
end
