defmodule EHealth.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias Core.API.Signature

  test "valid digital signature" do
    {:ok, %{"meta" => %{"code" => 200}, "data" => data}} =
      Signature.decode_and_validate(get_signed_content(), "base64", [{"edrpou", "38782323"}])

    [signature] = data["signatures"]

    assert signature["is_valid"]
    assert Map.has_key?(signature["signer"], "edrpou")
  end

  test "invalid base64 signed content" do
    {:error, %{"meta" => %{"code" => 422}}} =
      Signature.decode_and_validate("invalid", "base64", [{"edrpou", "38782323"}])
  end

  defp get_signed_content do
    "test/data/signed_content.json"
    |> File.read!()
    |> Base.encode64()
  end
end
