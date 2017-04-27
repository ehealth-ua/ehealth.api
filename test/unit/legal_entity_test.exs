defmodule EHealth.Unit.LegalEntityTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.LegalEntity.API
  alias EHealth.LegalEntity.Validator

  test "successed signed content validation" do
    content = File.read!("test/data/signed_content.txt")

    Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "invalid signed content validation" do
    Validator.decode_and_validate(%{
      "signed_content_encoding" => "base256",
      "signed_legal_entity_request" => "invalid"
    })
  end

  test "validate decoded legal entity" do
    content = get_legal_entity_data()

    data = %{"data" => %{"content" => content}}

    assert {:ok, %{"content" => content}} == Validator.validate_legal_entity({:ok, data})
  end

  test "validate legal entity EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "37367387"}

    assert {:ok, content} == validate_edrpou(content, signer)
  end

  test "empty signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"empty" => "37367387"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "invalid signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "03736738a"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "different signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "0373167387"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "process new legal entity" do
    legal_entitity = Map.merge(get_legal_entity_data(), %{"edrpou" => "07316730", "name" => "Nebo15 corp."})

    assert {:ok, %{"data" => resp}} = API.process_request({:ok, legal_entitity}, get_headers())
    assert "Nebo15 corp." == resp["name"]
    assert "07316730" == resp["edrpou"]
  end

  test "process legal entity that exists" do
    legal_entitity = Map.merge(get_legal_entity_data(), %{
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })

    assert {:ok, %{"data" => resp}} = API.process_request({:ok, legal_entitity}, get_headers())
    assert "Nebo15" == resp["short_name"]
    assert "37367387" == resp["edrpou"]
    assert "changed@example.com" == resp["email"]
    assert ["86.1"] == resp["kveds"]
  end

  # helpers

  defp get_headers do
    [{"content-type", "application/json"}, {"x-consumer-id", Ecto.UUID.generate()}]
  end

  defp validate_edrpou(content, signer) do
    Validator.validate_edrpou({:ok, %{
      "content" => content,
      "signer" => signer
    }})
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Poison.decode!()
  end
end
