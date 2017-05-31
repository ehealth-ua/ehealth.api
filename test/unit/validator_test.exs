defmodule EHealth.Unit.ValidatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias EHealth.LegalEntity.Validator
  alias EHealth.API.MediaStorage

  @phone_type %{
    "name" => "PHONE_TYPE",
    "values" => %{
      "MOBILE" => "mobile",
      "LANDLINE" => "landline",
    },
    "labels" => ["SYSTEM"],
    "is_active" => true,
  }

  @unmapped %{
    "name" => "UNMAPPED",
    "values" => %{
      "NEW" => "yes",
    },
    "labels" => ["SYSTEM"],
    "is_active" => true,
  }

  test "JSON schema dictionary enum validate PHONE_TYPE", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> Map.put("phones", [%{"type" => "INVALID", "number" => "+380503410870"}])

    assert {:error, [{%{description: "value is not allowed in enum", rule: :inclusion}, "$.phones.[0].type"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema birth_date date format", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["owner", "birth_date"], "1988.12.11")

    assert {:error, [{%{description: _, rule: :format}, "$.owner.birth_date"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "unmapped dictionary name", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "UNMAPPED"), @unmapped

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()

    assert {:ok, _} = Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "base64 decode signed_content with white spaces" do
    signed_content = File.read!("test/data/signed_content_whitespace.txt")
    data = {:ok, %{"data" => %{"secret_url" => "http://localhost:4040/signed_url_test"}}}

    assert {:ok, "http://example.com?signed_url=true"} == MediaStorage.put_signed_content(data, signed_content)
  end
end
