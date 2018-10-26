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
           "signatures" =>
             Enum.map(drfos, fn %{drfo: drfo} = signer ->
               %{
                 "is_valid" => true,
                 "is_stamp" => signer[:is_stamp],
                 "signer" => %{"drfo" => drfo, "surname" => signer[:surname]}
               }
             end)
         }
       }}
    end)
  end

  def drfo_signed_content(params, drfo, surname \\ "Нечуй-Левицький") do
    drfo_signed_content(params, [%{drfo: drfo, surname: surname}])
  end

  def edrpou_signed_content(params, edrpous) when is_list(edrpous) do
    expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
      {:ok,
       %{
         "data" => %{
           "content" => params,
           "signatures" =>
             Enum.map(edrpous, fn edrpou ->
               case is_map(edrpou) do
                 true ->
                   %{"is_valid" => true, "is_stamp" => edrpou[:is_stamp], "signer" => %{"edrpou" => edrpou[:edrpou]}}

                 _ ->
                   %{"is_valid" => true, "is_stamp" => false, "signer" => %{"edrpou" => edrpou}}
               end
             end)
         }
       }}
    end)
  end

  def edrpou_signed_content(params, edrpou) do
    edrpou_signed_content(params, [edrpou])
  end
end
