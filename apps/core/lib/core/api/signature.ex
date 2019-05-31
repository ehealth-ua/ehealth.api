defmodule Core.API.Signature do
  @moduledoc """
  Signature validator and data mapper
  """

  use Confex, otp_app: :core

  import Core.API.Helpers.Connection, only: [get_header: 2]
  import Core.Utils.TypesConverter, only: [atoms_to_strings: 1]

  alias Core.ValidationError
  alias Core.Validators.Error

  require Logger

  @behaviour Core.API.SignatureBehaviour
  @rpc_worker Application.get_env(:core, :rpc_worker)

  def decode_and_validate(signed_content, headers) do
    # explicit cast to boolean because of confex does not resolve env in tests
    enabled? = config()[:enabled] == true

    do_decode_and_validate(enabled?, signed_content, headers)
  end

  defp do_decode_and_validate(true, signed_content, _) do
    signature_result = @rpc_worker.run("ds_api", API.Rpc, :decode_signed_content, [signed_content])

    with {:ok, %{content: content, signatures: signatures}} <- signature_result do
      {:ok, %{"content" => atoms_to_strings(content), "signatures" => atoms_to_strings(signatures)}}
    else
      {:error, {:invalid_content, error_description, _}} ->
        invalid_json_error(error_description)

      {:error, [{%{description: "Not a base64 string"}, _}]} ->
        base64_error()

      _ ->
        {:error, {:bad_request, "Invalid signature"}}
    end
  end

  defp do_decode_and_validate(false, signed_content, headers) do
    with {:base64, {:ok, json_content}} <- {:base64, Base.decode64(signed_content)},
         {:json, {:ok, content}} <- {:json, Jason.decode(json_content)} do
      format_content_and_signatures(content, headers)
    else
      {:base64, _} -> base64_error()
      {:json, _} -> invalid_json_error("Malformed encoded content. Probably, you have encoded corrupted JSON.")
    end
  end

  defp format_content_and_signatures(content, headers) do
    signatures = [
      %{
        "is_valid" => true,
        "signer" => %{
          "drfo" => get_header(headers, "drfo"),
          "edrpou" => get_header(headers, "edrpou"),
          "surname" => headers |> get_header("surname") |> uri_decode(),
          "given_name" => headers |> get_header("given_name") |> uri_decode()
        },
        "validation_error_message" => ""
      }
    ]

    signatures =
      case get_header(headers, "msp_drfo") do
        nil ->
          signatures

        msp_drfo ->
          msp_signature = %{
            "is_valid" => true,
            "signer" => %{
              "drfo" => msp_drfo
            },
            "validation_error_message" => ""
          }

          [msp_signature | signatures]
      end

    {:ok, %{"content" => content, "signatures" => signatures}}
  end

  defp invalid_json_error(error_description) do
    Error.dump(%ValidationError{description: error_description, rule: "invalid", path: "$.signed_content"})
  end

  defp base64_error do
    Error.dump(%ValidationError{description: "Not a base64 string", rule: "invalid", path: "$.signed_content"})
  end

  defp uri_decode(string) when is_binary(string), do: URI.decode(string)
  defp uri_decode(string), do: string
end
