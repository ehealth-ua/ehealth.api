defmodule Core.Expectations.Signature do
  @moduledoc false

  import Mox

  def invalid_signed_content do
    expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
      {:error,
       %{
         "error" => %{
           "invalid" => [
             %{
               "entry" => "$.signed_content",
               "entry_type" => "json_data_property",
               "rules" => [
                 %{
                   "description" => "Not a base64 string",
                   "params" => [],
                   "rule" => "invalid"
                 }
               ]
             }
           ],
           "type" => "validation_failed"
         },
         "meta" => %{
           "code" => 422
         }
       }}
    end)
  end

  def drfo_signed_content(params, drfos) when is_list(drfos) do
    expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
      {:ok,
       %{
         "data" => %{
           "content" => params,
           "signatures" => Enum.map(drfos, fn drfo -> %{"is_valid" => true, "signer" => %{"drfo" => drfo}} end)
         }
       }}
    end)
  end

  def drfo_signed_content(params, drfo) do
    drfo_signed_content(params, [drfo])
  end

  def edrpou_signed_content(params, edrpous) when is_list(edrpous) do
    expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
      {:ok,
       %{
         "data" => %{
           "content" => params,
           "signatures" => Enum.map(edrpous, fn edrpou -> %{"is_valid" => true, "signer" => %{"edrpou" => edrpou}} end)
         }
       }}
    end)
  end

  def edrpou_signed_content(params, edrpou) do
    edrpou_signed_content(params, [edrpou])
  end
end
