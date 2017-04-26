defmodule EHealth.Unit.LegalEntityTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.LegalEntity.Validator

  test "legal entity creation" do
    content = File.read!("test/data/signed_content.txt")

    Validator.validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "invalid legal entity creation" do
    Validator.validate(%{
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
