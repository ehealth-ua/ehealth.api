defmodule EHealth.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.API.Signature

  test "valid digital signature" do
    assert {:ok, %{"meta" => %{"code" => 200}, "data" => data}} = resp =
      get_signed_content()
      |> Signature.decode_and_validate("base64", [{"edrpou", "38782323"}])

    assert data["is_valid"]
    assert Map.has_key?(data, "signer")
    assert Map.has_key?(data["signer"], "edrpou")

    "38782323" = Signature.extract_edrpou(resp)
  end

  test "invalid base64 signed content" do
    assert {:error, %{"meta" => %{"code" => 422}}} = Signature.decode_and_validate(
      "invalid", "base64",
      [{"edrpou", "38782323"}]
    )
  end

  defp get_signed_content do
    File.read!("test/data/signed_content.json")
  end
end
