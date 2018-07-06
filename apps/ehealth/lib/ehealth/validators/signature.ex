defmodule EHealth.Validators.Signature do
  @moduledoc false

  @signature_api Application.get_env(:ehealth, :api_resolvers)[:digital_signature]

  def validate(signed_content, encoding, headers, required_signatures \\ 1) do
    with {:ok, %{"data" => data}} <- @signature_api.decode_and_validate(signed_content, encoding, headers) do
      process_data(data, required_signatures)
    end
  end

  defp process_data(
         %{"content" => content, "signatures" => signatures},
         required_signatures
       )
       when is_list(signatures) do
    if Enum.count(signatures) == required_signatures do
      # return the last signature (they are in reverse order)
      get_last_signer(content, List.first(signatures))
    else
      signer_msg = if required_signatures == 1, do: "signer", else: "signers"

      {:error,
       {:bad_request,
        "document must be signed by #{required_signatures} #{signer_msg} but contains #{Enum.count(signatures)} signatures"}}
    end
  end

  defp get_last_signer(content, %{"is_valid" => true, "signer" => signer}) do
    {:ok, %{"content" => content, "signer" => signer}}
  end

  defp get_last_signer(_, %{"is_valid" => false, "validation_error_message" => error}),
    do: {:error, {:bad_request, error}}
end
