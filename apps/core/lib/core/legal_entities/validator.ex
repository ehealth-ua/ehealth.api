defmodule Core.LegalEntities.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  import Ecto.Changeset

  alias Core.Email.Sanitizer
  alias Core.LegalEntities.LegalEntity
  alias Core.ValidationError
  alias Core.Validators.Addresses
  alias Core.Validators.BirthDate
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects
  alias Core.Validators.JsonSchema
  alias Core.Validators.KVEDs
  alias Core.Validators.Signature, as: SignatureValidator
  alias Core.Validators.TaxID

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)

  def decode_and_validate(params, headers) do
    with :ok <- JsonSchema.validate(:legal_entity_sign, params),
         {_, {:ok, %{"content" => content, "signer" => signer}}} <-
           {:signed_content,
            SignatureValidator.validate(
              params["signed_legal_entity_request"],
              params["signed_content_encoding"],
              headers
            )},
         :ok <- JsonSchema.validate(:legal_entity, content),
         content = lowercase_emails(content),
         :ok <- validate_json_objects(content),
         :ok <- validate_type(content),
         :ok <- validate_kveds(content),
         :ok <- validate_addresses(content, headers),
         :ok <- validate_tax_id(content),
         :ok <- validate_owner_birth_date(content),
         :ok <- validate_owner_position(content),
         :ok <- validate_edrpou(content, signer) do
      {:ok, content}
    else
      {:signed_content, {:error, {:bad_request, reason}}} ->
        Error.dump(%ValidationError{description: reason, path: "$.signed_legal_entity_request"})

      error ->
        error
    end
  end

  def validate_json_objects(content) do
    with :ok <- JsonObjects.array_unique_by_key(content, ["addresses"], "type"),
         :ok <- JsonObjects.array_unique_by_key(content, ["phones"], "type"),
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "phones"], "type"),
         :ok <- JsonObjects.array_unique_by_key(content, ["owner", "documents"], "type"),
         do: :ok
  end

  defp validate_type(%{"type" => @msp}), do: :ok
  defp validate_type(%{"type" => @pharmacy}), do: :ok
  defp validate_type(_), do: Error.dump("Only legal_entity with type MSP or Pharmacy could be created")

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
        Error.dump(%ValidationError{description: "'no_tax_id' must be false", path: "$.owner.no_tax_id"})

      _ ->
        content
        |> get_in(["owner", "tax_id"])
        |> TaxID.validate(%ValidationError{description: "invalid tax_id value", path: "$.owner.tax_id"})
    end
  end

  # EDRPOU content to EDRPOU / DRFO signer validator
  def validate_edrpou(content, %{"edrpou" => edrpou} = signer)
      when is_nil(edrpou) or edrpou == "",
      do: validate_edrpou(content, Map.delete(signer, "edrpou"))

  def validate_edrpou(content, %{"edrpou" => _edrpou} = signer) do
    data = %{}
    types = %{edrpou: :string}

    {data, types}
    |> cast(signer, Map.keys(types))
    |> validate_required(Map.keys(types))
    |> validate_format(:edrpou, ~r/^[0-9]{8,10}$/)
    |> validate_inclusion(:edrpou, [content_edrpou(content)])
    |> is_valid_content(content)
  end

  def validate_edrpou(content, %{"drfo" => _drfo} = signer) do
    data = %{}
    types = %{drfo: :string}

    {data, types}
    |> cast(signer, Map.keys(types))
    |> validate_required(Map.keys(types))
    |> validate_format(:drfo, ~r/^[0-9]{9,10}$/ui)
    |> validate_inclusion(:drfo, [content_edrpou(content)])
    |> is_valid_content(content)
  end

  def validate_edrpou(_content, _signer) do
    Error.dump(%ValidationError{description: "EDRPOU and DRFO is empty in digital sign", path: "$.data.signatures"})
  end

  defp content_edrpou(content) do
    content
    |> legal_entity_edrpou()
    |> String.upcase()
  end

  defp legal_entity_edrpou(%{"edrpou" => edrpou}), do: edrpou
  defp legal_entity_edrpou(%LegalEntity{edrpou: edrpou}), do: edrpou

  defp is_valid_content(%Ecto.Changeset{valid?: true}, _), do: :ok

  defp is_valid_content(changeset, _content), do: {:error, changeset}

  def validate_owner_birth_date(content) do
    content
    |> get_in(["owner", "birth_date"])
    |> BirthDate.validate()
    |> case do
      true ->
        :ok

      _ ->
        Error.dump(%ValidationError{description: "invalid birth_date value", path: "$.owner.birth_date"})
    end
  end

  def validate_owner_position(content) do
    conf_positions = Confex.fetch_env!(:core, __MODULE__)[:owner_positions]

    content
    |> get_in(["owner", "position"])
    |> valid_owner_position?(conf_positions)
    |> case do
      true ->
        :ok

      _ ->
        Error.dump(%ValidationError{description: "invalid owner position value", path: "$.owner.position"})
    end
  end

  defp valid_owner_position?(_position, nil), do: false

  defp valid_owner_position?(position, positions), do: Enum.any?(positions, fn x -> x == position end)

  defp lowercase_emails(content) do
    email = Map.get(content, "email")
    path = ~w(owner email)
    owner_email = get_in(content, path)

    content
    |> Map.put("email", Sanitizer.sanitize(email))
    |> put_in(path, Sanitizer.sanitize(owner_email))
  end
end
