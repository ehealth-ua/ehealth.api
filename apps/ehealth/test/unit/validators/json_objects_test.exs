defmodule EHealth.Unit.Validators.JsonObjectsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias EHealth.ValidationError
  alias EHealth.Validators.JsonObjects

  @valid_path ["person", "details", "documents"]
  @invalid_path ["person", "details", "something"]
  @object %{
    "person" => %{
      "details" => %{
        "documents" => [
          %{"type" => "passport", "serial" => 12345},
          %{"type" => "national_id", "serial" => 67890}
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
      assert %ValidationError{
               description: "Key not found",
               params: [],
               path: "$.person.details.something",
               rule: :invalid
             } == JsonObjects.get_value_in(@object, @invalid_path)
    end

    test "get_keys/2 can return object keys by given key element name" do
      objects = [
        %{"type" => "passport", "serial" => 12345},
        %{"type" => "national_id", "serial" => 67890}
      ]

      assert ["passport", "national_id"] == JsonObjects.get_keys(objects, "type")
    end

    test "combine_path/2 can combine validation path inside object" do
      assert "$.upper_level.propA[0].propB" == JsonObjects.combine_path("upper_level", "$.propA[0].propB")
    end
  end

  describe "array_unique_by_key/4" do
    test "returns :ok when array of objects contains only unique elements under given key name" do
      assert :ok == JsonObjects.array_unique_by_key(@object, @valid_path, "type")
    end

    test "returns {:error, _} when array of objects contains duplicate elemenkeysts under given key name" do
      duplicates = [
        %{"type" => "passport", "serial" => 12345},
        %{"type" => "passport", "serial" => 67890}
      ]

      object = put_in(@object, @valid_path, duplicates)

      assert %ValidationError{
               description: "No duplicate values.",
               params: ["passport"],
               path: "$.person.details.documents[1].type",
               rule: :invalid
             } = JsonObjects.array_unique_by_key(object, @valid_path, "type")
    end
  end

  describe "array_single_item/4" do
    setup _context do
      single_object = %{
        "person" => %{
          "details" => %{
            "documents" => [
              %{"type" => "passport", "serial" => 12345}
            ]
          }
        }
      }

      {:ok, single_object: single_object}
    end

    test "returns :ok when array contains only one valid item", %{single_object: single_object} do
      assert :ok == JsonObjects.array_single_item(single_object, @valid_path, "type")
    end

    test "returns error when array contains more than one object" do
      assert %ValidationError{
               description: "Must contain only one valid item.",
               params: [],
               path: "$.person.details.documents[0].type",
               rule: :invalid
             } = JsonObjects.array_single_item(@object, @valid_path, "type")
    end
  end

  describe "array_item_required/3" do
    test "returns :ok when array contains required object under given key name" do
      assert :ok == JsonObjects.array_item_required(@object, @valid_path, "type", "passport")
    end

    test "returns {:error, _} when array doesn't contains required object under given key name" do
      non_required = [%{"type" => "national_id", "serial" => 67890}]
      object = put_in(@object, @valid_path, non_required)

      assert %ValidationError{
               description: "Must contain required item.",
               params: ["passport"],
               path: "$.person.details.documents[].type",
               rule: :invalid
             } = JsonObjects.array_item_required(object, @valid_path, "type", "passport")
    end
  end
end
