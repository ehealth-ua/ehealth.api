defmodule Core.V2.LegalEntities.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Validator
  alias Core.ValidationError
  alias Core.Validators.Addresses
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature, as: SignatureValidator

  @pharmacy LegalEntity.type(:pharmacy)

  def decode_and_validate(params, headers) do
    with :ok <- JsonSchema.validate(:legal_entity_sign, params),
         {_, {:ok, %{"content" => content, "signers" => [signer]}}} <-
           {:signed_content, SignatureValidator.validate(params["signed_legal_entity_request"], headers)},
         :ok <- JsonSchema.validate(:legal_entity_v2, content),
         content <- lowercase_emails(content),
         :ok <- validate_json_objects(content),
         :ok <- validate_pharmacy_license_number(content["license"]),
         :ok <- Addresses.validate(content["residence_address"]),
         :ok <- validate_tax_id(content),
         :ok <- validate_owner_birth_date(content),
         :ok <- validate_owner_position(content),
         {:ok, legal_entity_code} <- validate_state_registry_number(content, signer) do
      {:ok, content, legal_entity_code}
    else
      {:signed_content, {:error, {:bad_request, reason}}} ->
        Error.dump(%ValidationError{description: reason, path: "$.signed_legal_entity_request"})

      error ->
        error
    end
  end

  defp validate_pharmacy_license_number(%{"type" => @pharmacy, "license_number" => value}) when not is_nil(value) do
    :ok
  end

  defp validate_pharmacy_license_number(%{"type" => @pharmacy}) do
    Error.dump(%ValidationError{
      description: "license_number is required for legal_entity with type-based PHARMACY",
      path: "$.license.license_number"
    })
  end

  defp validate_pharmacy_license_number(_), do: :ok

  def validate_json_objects(content) do
    with :ok <- JsonObjects.array_unique_by_key(content, ["phones"], "type"),
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "phones"], "type"),
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "documents"], "type"),
         do: :ok
  end

  defdelegate validate_tax_id(content), to: Validator
  defdelegate validate_state_registry_number(content, signer), to: Validator
  defdelegate validate_owner_birth_date(content), to: Validator

  defdelegate validate_owner_position(content), to: Validator
  defdelegate lowercase_emails(content), to: Validator
end
