defmodule EHealth.LegalEntities.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  import Ecto.Changeset

  alias EHealth.Validators.Signature, as: SignatureValidator
  alias EHealth.Validators.KVEDs
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.LegalEntities.LegalEntityRequest
  alias EHealth.Validators.TaxID
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.JsonSchema
  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries
  alias EHealth.Email.Sanitizer

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)
  @validation_dictionaries [
    "ADDRESS_TYPE",
    "PHONE_TYPE",
    "DOCUMENT_TYPE"
  ]

  def decode_and_validate(params, headers) do
    with {:ok, %{"content" => content, "signer" => signer}} <- validate_sign_content(params, headers) do
      validate_json(content, signer, headers)
    end
  end

  def validate_sign_content(content, headers) do
    content
    |> validate_request()
    |> validate_signature(headers)
    |> normalize_signature_error()
  end

  def validate_json(content, signer, headers) do
    with :ok <- validate_schema(content),
         content = lowercase_emails(content),
         :ok <- validate_json_objects(content),
         :ok <- validate_type(content),
         :ok <- validate_kveds(content),
         :ok <- validate_addresses(content, headers),
         :ok <- validate_tax_id(content),
         :ok <- validate_owner_birth_date(content),
         :ok <- validate_owner_position(content),
         :ok <- validate_edrpou(content, signer) do
      :ok
    end
  end

  # Request validator

  def validate_request(params) do
    fields = ~W(
      signed_legal_entity_request
      signed_content_encoding
    )a

    %LegalEntityRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}, headers) do
    SignatureValidator.validate(
      Map.get(changes, :signed_legal_entity_request),
      Map.get(changes, :signed_content_encoding),
      headers
    )
  end

  def validate_signature(err, _), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %LegalEntityRequest{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end

  def normalize_signature_error({:error, %{"error" => %{"message" => message}, "meta" => %{"code" => code}}}) do
    %LegalEntityRequest{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, "#{code}: #{message}")
  end

  def normalize_signature_error(ok_resp), do: ok_resp

  def validate_schema(content) do
    JsonSchema.validate(:legal_entity, content)
  end

  def validate_json_objects(content) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"ADDRESS_TYPE" => address_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(content, ["addresses"], "type", address_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(content, ["phones"], "type", phone_types),
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "phones"], "type", phone_types),
         %{"DOCUMENT_TYPE" => document_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "documents"], "type", document_types),
         do: :ok
  end

  defp validate_type(%{"type" => @msp}), do: :ok
  defp validate_type(%{"type" => @pharmacy}), do: :ok

  defp validate_type(_) do
    {:error, {:"422", "Only legal_entity with type MSP or Pharmacy could be created"}}
  end

  def validate_kveds(content) do
    content
    |> Map.get("kveds")
    |> KVEDs.validate(content["type"])
    |> case do
      %Ecto.Changeset{valid?: false} = err -> {:error, err}
      _ -> :ok
    end
  end

  # Addresses validator

  def validate_addresses(content, headers) do
    addresses = Map.get(content, "addresses") || []
    Addresses.validate(addresses, "REGISTRATION", headers)
  end

  # Tax ID validator
  def validate_tax_id(content) do
    no_tax_id = get_in(content, ["owner", "no_tax_id"])

    case no_tax_id do
      true ->
        {:error,
         [
           {%{
              description: "'no_tax_id must be false",
              params: [],
              rule: :invalid
            }, "$.owner.no_tax_id"}
         ]}

      _ ->
        content
        |> get_in(["owner", "tax_id"])
        |> TaxID.validate()
        |> case do
          true ->
            :ok

          _ ->
            {:error,
             [
               {%{
                  description: "invalid tax_id value",
                  params: [],
                  rule: :invalid
                }, "$.owner.tax_id"}
             ]}
        end
    end
  end

  # EDRPOU validator

  def validate_edrpou(content, signer) do
    data = %{}
    types = %{edrpou: :string}

    {data, types}
    |> cast(signer, Map.keys(types))
    |> validate_required(Map.keys(types))
    |> validate_format(:edrpou, ~r/^[0-9]{8,10}$/)
    |> validate_inclusion(:edrpou, [Map.fetch!(content, "edrpou")])
    |> prepare_legal_entity(content)
  end

  def validate_owner_birth_date(content) do
    content
    |> get_in(["owner", "birth_date"])
    |> BirthDate.validate()
    |> case do
      true ->
        :ok

      _ ->
        {:error,
         [
           {%{
              description: "invalid birth_date value",
              params: [],
              rule: :invalid
            }, "$.owner.birth_date"}
         ]}
    end
  end

  def validate_owner_position(content) do
    conf_positions = Confex.fetch_env!(:ehealth, __MODULE__)[:owner_positions]

    content
    |> get_in(["owner", "position"])
    |> valid_owner_position?(conf_positions)
    |> case do
      true ->
        :ok

      _ ->
        {:error,
         [
           {%{
              description: "invalid owner position value",
              params: [],
              rule: :invalid
            }, "$.owner.position"}
         ]}
    end
  end

  defp valid_owner_position?(_position, nil), do: false
  defp valid_owner_position?(position, positions), do: Enum.any?(positions, fn x -> x == position end)

  defp prepare_legal_entity(%Ecto.Changeset{valid?: true}, legal_entity), do: {:ok, legal_entity}
  defp prepare_legal_entity(changeset, _legal_entity), do: {:error, changeset}

  defp lowercase_emails(content) do
    email = Map.get(content, "email")
    path = ~w(owner email)
    owner_email = get_in(content, path)

    content
    |> Map.put("email", Sanitizer.sanitize(email))
    |> put_in(path, Sanitizer.sanitize(owner_email))
  end
end
