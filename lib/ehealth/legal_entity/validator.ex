defmodule EHealth.LegalEntity.Validator do
  @moduledoc """
  Request, TaxID, Digital signature validators
  """

  use JValid

  import Ecto.Changeset

  alias EHealth.API.Signature
  alias EHealth.LegalEntity.Request
  alias EHealth.Utils.ValidationSchemaMapper
  alias EHealth.LegalEntity.ValidatorKVEDs
  alias EHealth.API.UAddress

  use_schema :legal_entity, "specs/json_schemas/new_legal_entity_schema.json"

  def decode_and_validate(params) do
    params
    |> validate_request()
    |> validate_signature()
    |> normalize_signature_error()
    |> validate_legal_entity()
    |> validate_kveds()
    |> validate_addresses()
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
    {:error, {:validation_error, "Signed request data is invalid"}}
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

  def validate_kveds({:ok, %{"content" => content}} = result) do
    content
    |> Map.get("kveds")
    |> ValidatorKVEDs.validate()
    |> case do
         %Ecto.Changeset{valid?: false} = err -> {:error, err}
         _ -> result
       end
  end
  def validate_kveds(err), do: err

  # Addresses validator

  def validate_addresses({:ok, _} = result) do
    result
    |> validate_addresses_type()
    |> validate_addresses_values()
  end

  def validate_addresses(err), do: err

  defp validate_addresses_type({:ok, %{"content" => content}} = result) do
    addresses_count =
      content
      |> Map.get("addresses")
      |> Enum.filter(fn(x) -> Map.get(x, "type") == "REGISTRATION" end)
      |> length()

    case addresses_count do
      1 -> result
      _ -> {:error, [{%{description: "one and only one registration address is required", params: [], rule: :invalid},
        "$.addresses"}]}
    end
  end

  defp validate_addresses_type(err), do: err

  defp validate_addresses_values({:ok, %{"content" => content}} = result) do
    content
    |> Map.get("addresses")
    |> Enum.reduce([], &validate_address_values/2)
    |> return_addresses_values_validation_result(result)
  end

  defp validate_addresses_values(err), do: err

  defp validate_address_values(address, errors) do
    address
    |> Map.get("settlement_id")
    |> UAddress.get_settlement_by_id()
    |> validate_settlement(address)
    |> Kernel.++(errors)
  end

  defp validate_settlement({:error, _error}, address) do
    settlement_id = Map.get(address, "settlement_id")
    [{%{
      description: "settlement with id = #{settlement_id} does not exist",
      params: [],
      rule: :not_found
    }, "$.addresses.settlement_id"}]
  end

  defp validate_settlement({:ok, %{"meta" => _meta, "data" => data}}, address) do
    case get_map_upcase_value(data, "name") == get_map_upcase_value(address, "settlement") do
      true -> get_region_info(data, address)
      _ -> [{%{
        description: "invalid settlement value",
        params: [],
        rule: :invalid
      }, "$.addresses.settlement"}]
    end
  end

  defp get_region_info(data, address) do
    data
    |> Map.get("region_id")
    |> UAddress.get_region_by_id()
    |> validate_region(data, address)
  end

  defp validate_region({:error, _error}, _settlement, address) do
    region_id = Map.get(address, "region_id")
    [{%{
      description: "region with id = #{region_id} does not exist",
      params: [],
      rule: :not_found
    }, "$.addresses.settlement.region_id"}]
  end

  defp validate_region({:ok, %{"meta" => _meta, "data" => data}}, settlement, address) do
    case get_map_upcase_value(data, "name") == get_map_upcase_value(address, "area") do
      true -> get_district_info(settlement, address)
      _ -> [{%{
        description: "invalid area value",
        params: [],
        rule: :invalid
      }, "$.addresses.area"}]
    end
  end

  defp get_district_info(data, address) do
    data
    |> Map.get("district_id")
    |> check_district(address)
  end

  defp check_district(nil, _address), do: []
  defp check_district(district_id, address) do
    district_id
    |> UAddress.get_district_by_id()
    |> validate_district(address)
  end

  defp validate_district({:error, _error}, address) do
    district_id = Map.get(address, "district_id")
    [{%{
      description: "district with id = #{district_id} does not exist",
      params: [],
      rule: :not_found
    }, "$.addresses.settlement.district_id"}]
  end

  defp validate_district({:ok, %{"meta" => _meta, "data" => data}}, address) do
    case get_map_upcase_value(data, "name") == get_map_upcase_value(address, "region") do
      true -> []
      _ -> [{%{
        description: "invalid region value",
        params: [],
        rule: :invalid
      }, "$.addresses.region"}]
    end
  end

  defp return_addresses_values_validation_result([], result), do: result
  defp return_addresses_values_validation_result(errors, _result), do: errors

  defp get_map_upcase_value(map, key) do
    map
    |> Map.get(key, "")
    |> String.upcase()
  end

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

  def validate_edrpou(err), do: err

  def prepare_legal_entity(%Ecto.Changeset{valid?: true}, legal_entity) do
    {:ok, %{legal_entity_request: legal_entity}}
  end
  def prepare_legal_entity(changeset, _legal_entity), do: changeset
end
