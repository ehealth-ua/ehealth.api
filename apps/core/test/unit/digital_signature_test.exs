defmodule Core.Unit.DigitalSignatureTest do
  @moduledoc false

  use ExUnit.Case, async: true
  import Core.Expectations.Signature

  alias Core.API.Signature

  test "valid digital signature" do
    {:ok, %{"signatures" => [signature]}} =
      Signature.decode_and_validate(get_signed_content(), [{"edrpou", "38782323"}])

    assert signature["is_valid"]
    assert Map.has_key?(signature["signer"], "edrpou")
  end

  test "invalid base64 signed content" do
    error = {:error, [{%{description: "Not a base64 string", params: [], rule: "invalid"}, "$.signed_content"}]}

    assert error == Signature.decode_and_validate("invalid", [{"edrpou", "38782323"}])
  end

  test "invalid json format of signed content" do
    error =
      {:error,
       [
         {%{
            description: "Malformed encoded content. Probably, you have encoded corrupted JSON.",
            params: [],
            rule: "invalid"
          }, "$.signed_content"}
       ]}

    assert error == Signature.decode_and_validate(Base.encode64("invalid"), [{"edrpou", "38782323"}])
  end

  defp get_signed_content do
    "test/data/signed_content.json"
    |> File.read!()
    |> Base.encode64()
  end
end
