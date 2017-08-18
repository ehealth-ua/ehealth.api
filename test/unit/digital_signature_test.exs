defmodule EHealth.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case

  alias EHealth.API.Signature

  test "valid digital signature" do
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145")
    assert {:ok, %{"meta" => %{"code" => 200}, "data" => data}} = resp =
      "test/data/signed_content.txt"
      |> File.read!()
      |> Signature.decode_and_validate("base64")

    assert data["is_valid"]
    assert Map.has_key?(data, "signer")
    assert Map.has_key?(data["signer"], "edrpou")

    "38782323" = Signature.extract_edrpou(resp)
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://localhost:4040")
  end

  test "invalid base64 signed content" do
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145")
    assert {:error, %{"meta" => %{"code" => 422}}} =
      Signature.decode_and_validate("invalid", "base64")
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://localhost:4040")
  end
end
