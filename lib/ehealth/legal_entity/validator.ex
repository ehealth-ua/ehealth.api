defmodule EHealth.LegalEntity.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  use JValid

  import Ecto.Changeset

  alias EHealth.API.Signature
  alias EHealth.LegalEntity.Request
  alias EHealth.Utils.ValidationSchemaMapper

  use_schema :legal_entity, "specs/json_schemas/new_legal_entity_schema.json"

  def decode_and_validate(params) do
    params
    |> validate_request()
    |> validate_signature()
    |> normalize_signature_error()
    |> validate_legal_entity()
    |> validate_edrpou()
  end

  # Request validator

  def validate_request(params) do
    fields = ~W(
      signed_legal_entity_request
      signed_content_encoding
    )a

    %Request{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}) do
    Signature.decode_and_validate(changes)
  end
  def validate_signature(err), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %Request{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end
  def normalize_signature_error(ok_resp), do: ok_resp

  # Legal Entity content validator

  def validate_legal_entity({:ok, %{"data" => %{"is_valid" => false}}}) do
    {:error, "Signed request data is invalid"}
  end

  def validate_legal_entity({:ok, %{"data" => %{"content" => content} = data}}) do
    schema =
      @schemas
      |> Keyword.get(:legal_entity)
      |> ValidationSchemaMapper.prepare_legal_entity_schema()

    case validate_schema(schema, content) do
      :ok -> {:ok, data}
      err -> err
    end
  end

  def validate_legal_entity(err), do: err

  # Tax ID validator

  def validate_edrpou({:ok, %{"content" => content, "signer" => signer}}) do
    data  = %{}
    types = %{edrpou: :string}

    {data, types}
    |> cast(signer, Map.keys(types))
    |> validate_required(Map.keys(types))
    |> validate_format(:edrpou, ~r/^[0-9]{8,10}$/)
    |> validate_inclusion(:edrpou, [Map.fetch!(content, "edrpou")])
    |> prepare_legal_entity(content)
  end
  def validate_edrpou({:error, reason}), do: {:error, {:validation_error, reason}}
  def validate_edrpou(%Ecto.Changeset{} = ch), do: {:error, ch}
  def validate_edrpou(err), do: {:error, {:validation_error, err}}

  def prepare_legal_entity(%Ecto.Changeset{valid?: true}, legal_entity) do
    {:ok, %{legal_entity_request: legal_entity}}
  end
  def prepare_legal_entity(changeset, _legal_entity), do: changeset
end
