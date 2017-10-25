defmodule EHealth.Unit.Validators.JsonObjectsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias EHealth.Validators.JsonObjects

  @valid_path ["person", "details", "documents"]
  @invalid_path ["person", "details", "something"]

  @valid_types ["passport", "national_id"]

  @object %{
    "person" => %{
      "details" => %{
        "documents" => [
          %{ "type" => "passport", "serial" => 12345},
          %{ "type" => "national_id", "serial" => 67890}
        ]
      }
    }
  }

  describe "helper functions" do
    test "get_value_in/2 can get a under a given path" do
      {:ok, value} = JsonObjects.get_value_in(@object, @valid_path)

      assert value == get_in(@object, @valid_path)
    end

    test "get_value_in/2 returns error for invalid path" do
      assert {:error, [{"Key not found", "#/person/details/something"}]}
        == JsonObjects.get_value_in(@object, @invalid_path)
    end

    test "get_keys/2 can return object keys by given key element name" do
      objects = [
        %{ "type" => "passport", "serial" => 12345 },
        %{ "type" => "national_id", "serial" => 67890}
      ]

      assert ["passport", "national_id"] == JsonObjects.get_keys(objects, "type")
    end
  end

  describe "array_unique_by_key/4" do
    test "returns :ok when array of objects contains only unique elements under given key name" do
      assert :ok == JsonObjects.array_unique_by_key(@object, @valid_path, "type", @valid_types)
    end

    test "returns {:error, _} when array of objects contains duplicate elemenkeysts under given key name" do
      duplicates = [
        %{ "type" => "passport", "serial" => 12345 },
        %{ "type" => "passport", "serial" => 67890}
      ]
      object = put_in(@object, @valid_path , duplicates)

      result = JsonObjects.array_unique_by_key(object, @valid_path, "type", @valid_types)
      {:error, [{reason, path}]} = result

      assert reason == "Duplicate value 'passport'"
      assert path == "#/person/details/documents/type"
    end

    test "returns {:error, _} when array of objects contains unique keys but they are NOT in the valid list" do
      not_in_dict = [
        %{ "type" => "not_in_dict", "serial" => 12345 },
        %{ "type" => "passport", "serial" => 67890}
      ]
      object = put_in(@object, @valid_path , not_in_dict)

      result = JsonObjects.array_unique_by_key(object, @valid_path, "type", @valid_types)
      {:error, [{reason, path}]} = result

      assert reason == "Value 'not_in_dict' is not found in Dictionary"
      assert path == "#/person/details/documents/type"
    end
  end

  describe "array_single_valid_item/4" do
    setup _context do
        single_object = %{
          "person" => %{
            "details" => %{
              "documents" => [
                %{ "type" => "passport", "serial" => 12345 }
              ]
            }
          }
        }

        {:ok, single_object: single_object}
    end

    test "returns :ok when array contains only one valid item", %{single_object: single_object} do
      assert :ok == JsonObjects.array_single_valid_item(single_object, @valid_path, "type", @valid_types)
    end

    test "returns {:error, _} when array contains more than one object" do
      result = JsonObjects.array_single_valid_item(@object, @valid_path, "type", @valid_types)
      {:error, [{reason, path}]} = result

      assert reason == "More than one value found!"
      assert path == "#/person/details/documents/type"
    end

    test "returns {:error, _} when array contains only one object but value is not in a Dictionary",
      %{single_object: single_object} do

      not_in_dict = [%{ "type" => "not_in_dict", "serial" => 12345 }]
      object = put_in(single_object, @valid_path , not_in_dict)

      result = JsonObjects.array_single_valid_item(object, @valid_path, "type", @valid_types)
      {:error, [{reason, path}]} = result

      assert reason == "Value 'not_in_dict' is not found in Dictionary"
      assert path == "#/person/details/documents/type"
    end
  end

  describe "array_contains_item/3" do
    test "returns :ok when array contains required object under given key name" do
      assert :ok == JsonObjects.array_contains_item(@object, @valid_path, "type", "passport")
    end

    test "returns {:error, _} when array doesn't contains required object under given key name" do
      non_required = [%{ "type" => "national_id", "serial" => 67890}]
      object = put_in(@object, @valid_path, non_required)

      result = JsonObjects.array_contains_item(object, @valid_path, "type", "passport")
      {:error, [{reason, path}]} = result

      assert reason == "'passport' is required"
      assert path == "#/person/details/documents/type"
    end
  end
end
