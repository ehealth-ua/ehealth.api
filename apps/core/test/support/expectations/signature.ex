defmodule Core.Expectations.Signature do
  @moduledoc false

  import Mox

  alias Core.Validators.Error
  alias Core.ValidationError

  def invalid_signed_content do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      Error.dump(%ValidationError{description: "Not a base64 string", rule: "invalid", path: "$.signed_content"})
    end)
  end

  def invalid_signed_content_json_format do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      Error.dump(%ValidationError{
        description: "Malformed encoded content. Probably, you have encoded corrupted JSON.",
        rule: "invalid",
        path: "$.signed_content"
      })
    end)
  end

  def drfo_signed_content(content, drfos) when is_list(drfos) do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      {:ok,
       %{
         "content" => content,
         "signatures" =>
           Enum.map(drfos, fn %{drfo: drfo} = signer ->
             %{
               "is_valid" => true,
               "is_stamp" => signer[:is_stamp],
               "signer" => %{"drfo" => drfo, "surname" => signer[:surname]}
             }
           end)
       }}
    end)
  end

  def drfo_signed_content(content, drfo, surname \\ "Нечуй-Левицький") do
    drfo_signed_content(content, [%{drfo: drfo, surname: surname}])
  end

  def edrpou_signed_content(content, edrpous) when is_list(edrpous) do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      {:ok,
       %{
         "content" => content,
         "signatures" =>
           Enum.map(edrpous, fn edrpou ->
             case is_map(edrpou) do
               true ->
                 %{"is_valid" => true, "is_stamp" => edrpou[:is_stamp], "signer" => %{"edrpou" => edrpou[:edrpou]}}

               _ ->
                 %{"is_valid" => true, "is_stamp" => false, "signer" => %{"edrpou" => edrpou}}
             end
           end)
       }}
    end)
  end

  def edrpou_signed_content(content, edrpou) do
    edrpou_signed_content(content, [edrpou])
  end

  def expect_signed_content(content, signers) when is_list(signers) do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      {:ok,
       %{
         "content" => content,
         "signatures" =>
           Enum.map(signers, fn signer ->
             %{
               "is_valid" => Map.get(signer, :is_valid, true),
               "is_stamp" => Map.get(signer, :is_stamp, false),
               "signer" => %{"edrpou" => signer[:edrpou], "drfo" => signer[:drfo], "surname" => signer[:surname]}
             }
           end)
       }}
    end)
  end

  def expect_signed_content(content, signer) when is_map(signer) do
    expect(SignatureMock, :decode_and_validate, fn _, _ ->
      {:ok,
       %{
         "content" => content,
         "signatures" => [
           %{
             "is_valid" => Map.get(signer, :is_valid, true),
             "is_stamp" => Map.get(signer, :is_stamp, false),
             "signer" => %{"edrpou" => signer[:edrpou], "drfo" => signer[:drfo], "surname" => signer[:surname]}
           }
         ]
       }}
    end)
  end
end
