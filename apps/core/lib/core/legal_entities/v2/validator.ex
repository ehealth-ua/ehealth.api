defmodule Core.V2.LegalEntities.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Validator
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator
  alias Core.Validators.V2.KVEDs

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)
  @msp_pharmacy LegalEntity.type(:msp_pharmacy)

  def decode_and_validate(params, headers) do
    with :ok <- JsonSchema.validate(:legal_entity_sign, params),
         {_, {:ok, %{"content" => content, "signers" => [signer]}}} <-
           {:signed_content,
            SignatureValidator.validate(
              params["signed_legal_entity_request"],
              params["signed_content_encoding"],
              headers
            )},
         :ok <- JsonSchema.validate(:legal_entity_v2, content),
         content <- fill_legal_entity(content),
         licenses <- content["medical_service_provider"]["licenses"],
         :ok <- check_uniq_license_types(licenses),
         :ok <- validate_json_objects(content),
         :ok <- validate_license_type(licenses),
         :ok <- validate_pharmacy_license_number(licenses),
         :ok <- validate_licenses_kveds(licenses),
         :ok <- validate_addresses(content),
         :ok <- validate_tax_id(content),
         :ok <- validate_owner_birth_date(content),
         :ok <- validate_owner_position(content),
         {:ok, legal_entity_code} <- validate_state_registry_number(content, signer),
         :ok <- validate_edr(content, legal_entity_code) do
      {:ok, content}
    else
      {:signed_content, {:error, {:bad_request, reason}}} ->
        Error.dump(%ValidationError{description: reason, path: "$.signed_legal_entity_request"})

      error ->
        error
    end
  end

  defp check_uniq_license_types(licenses) do
    types = Enum.map(licenses, & &1["type"])
    uniq_types_count = types |> MapSet.new() |> MapSet.to_list() |> Enum.count()

    if uniq_types_count == Enum.count(types),
      do: :ok,
      else: Error.dump("Only unique with types (MSP or PHARMACY) could be created")
  end

  defp validate_license_type(licenses) do
    Enum.reduce_while(licenses, :ok, fn %{"type" => type}, _ ->
      if type in [@msp, @pharmacy, @msp_pharmacy],
        do: {:cont, :ok},
        else: {:halt, Error.dump("Only legal_entity with type MSP or PHARMACY or MSP_PHARMACY could be created")}
    end)
  end

  defp validate_pharmacy_license_number(licenses) do
    licenses
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {license, index}, _ ->
      cond do
        license["type"] in [@msp_pharmacy, @pharmacy] and license["license_number"] ->
          {:cont, :ok}

        license["type"] not in [@msp_pharmacy, @pharmacy] ->
          {:cont, :ok}

        true ->
          {:halt,
           Error.dump(%ValidationError{
             description: "license_number is required for legal_entity with type-based PHARMACY",
             path: "$.medical_service_provider.licenses.#{index}.license_number"
           })}
      end
    end)
  end

  defp validate_licenses_kveds(licenses) do
    licenses
    |> Enum.map(&validate_kveds(&1))
    |> List.flatten()
    |> Enum.reduce_while(:ok, fn
      :ok, _ -> {:cont, :ok}
      {:error, error}, _ -> {:halt, error}
    end)
  end

  defp fill_legal_entity(content) do
    licenses = content["medical_service_provider"]["licenses"]

    content
    |> lowercase_emails
    |> Map.merge(%{"kveds" => form_kveds(licenses), "type" => form_types(licenses)})
  end

  defp form_kveds(licenses) do
    licenses
    |> Enum.map(& &1["kveds"])
    |> List.flatten()
    |> MapSet.new()
    |> MapSet.to_list()
  end

  defp form_types(licenses) do
    licenses
    |> Enum.map(& &1["type"])
    |> Enum.sort()
    |> Enum.join("_")
  end

  defp validate_kveds(content) do
    content
    |> Map.get("kveds")
    |> KVEDs.validate(content["type"])
    |> case do
      %Ecto.Changeset{valid?: false} = err -> {:error, err}
      _ -> :ok
    end
  end

  defdelegate validate_addresses(content), to: Validator
  defdelegate validate_tax_id(content), to: Validator
  defdelegate validate_state_registry_number(content, signer), to: Validator
  defdelegate validate_owner_birth_date(content), to: Validator
  defdelegate validate_json_objects(content), to: Validator
  defdelegate validate_owner_position(content), to: Validator
  defdelegate lowercase_emails(content), to: Validator
  defdelegate validate_edr(content, legal_entity_code), to: Validator
end
