defmodule EHealth.Validators.Addresses do
  @moduledoc """
  KVED codes validator
  """
  alias EHealth.API.UAddress

  def validate(addresses, required_type) do
    addresses
    |> validate_addresses_type(required_type)
    |> validate_addresses_values()
  end

  defp validate_addresses_type(addresses, required_type) do
    addresses_count =
      addresses
      |> Enum.filter(fn(x) -> Map.get(x, "type") == required_type end)
      |> length()

    case addresses_count do
      1 -> {:ok, addresses}
      _ -> {:error, [{%{description: "Address of type '#{required_type}' is required", params: [], rule: :invalid},
        "$.addresses"}]}
    end
  end

  defp validate_addresses_values({:ok, addresses} = return) do
    addresses
    |> Enum.reduce([], &validate_address_values/2)
    |> return_addresses_values_validation_result(return)
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
  defp return_addresses_values_validation_result(errors, _result), do: {:error, errors}

  defp get_map_upcase_value(map, key) do
    map
    |> Map.get(key, "")
    |> String.upcase()
  end
end
