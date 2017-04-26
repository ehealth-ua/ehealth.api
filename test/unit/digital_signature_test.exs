defmodule EHealth.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.API.Signature

  test "valid digital signature" do
    assert {:ok, %{"meta" => %{"code" => 200}, "data" => data}} = resp =
      %{signed_content_encoding: "base64"}
      |> Map.put(:signed_legal_entity_request, File.read!("test/data/signed_content.txt"))
      |> Signature.validate()

    assert data["is_valid"]
    assert Map.has_key?(data, "signer")
    assert Map.has_key?(data["signer"], "edrpou")

    "38782323" = Signature.extract_edrpou(resp)
  end

  test "invalid base64 signed content" do
    assert {:error, %{"meta" => %{"code" => 422}}} =
      Signature.validate(%{
        signed_content_encoding: "base64",
        signed_legal_entity_request: "invalid"
      })
  end
end
