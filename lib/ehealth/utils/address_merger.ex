defmodule EHealth.Utils.AddressMerger do
  @moduledoc """
  Address merger
  """

  alias EHealth.Dictionaries

  @config Confex.get_map(:ehealth, EHealth.Utils.AddressMerger)

  def merge_address(nil), do: ""
  def merge_address(address) do
    area =
      address
      |> Map.get("area")
      |> to_string()
      |> check_area(@config[:no_suffix_areas])
      |> get_area()

    region =
      address
      |> Map.get("region")
      |> to_string()
      |> get_region()

    street_type =
      address
      |> Map.get("street_type")
      |> Dictionaries.get_dictionary_value("STREET_TYPE")
      |> to_string()

    building =
      address
      |> Map.get("building")
      |> to_string()

    street_part =
      address
      |> Map.get("street")
      |> to_string()
      |> get_street_part(street_type, building)

    settlement_type =
      address
      |> Map.get("settlement_type")
      |> Dictionaries.get_dictionary_value("SETTLEMENT_TYPE")
      |> to_string()

    settlement =
      address
      |> Map.get("settlement")
      |> to_string()
      |> get_settlement_part(settlement_type, street_part, building)

    apartment =
      address
      |> Map.get("apartment")
      |> to_string()
      |> get_apartment()

    zip =
      address
      |> Map.get("zip")
      |> to_string()
      |> get_zip()

      []
      |> Kernel.++(area)
      |> Kernel.++(region)
      |> Kernel.++(settlement)
      |> Kernel.++(street_part)
      |> Kernel.++(apartment)
      |> Kernel.++(zip)
      |> Enum.join(", ")
  end

  defp check_area("", _no_suffix_areas), do: {"", false}
  defp check_area(area, nil), do: {area, false}
  defp check_area(area, no_suffix_areas), do: {area, Enum.any?(no_suffix_areas, fn(x) -> x == String.upcase(area) end)}

  defp get_area({"", _no_suffix}), do: []
  defp get_area({area, false}), do: [area <> " область"]
  defp get_area({area, true}), do: [area]

  defp get_region(""), do: []
  defp get_region(region), do: [region <> " район"]

  defp get_street_type(street_list, ""), do: street_list ++ []
  defp get_street_type(street_list, street_type), do: street_list ++ [street_type]

  defp get_street(street_list, ""), do: street_list ++ []
  defp get_street(street_list, street), do: street_list ++ [street]

  defp get_building(street_list, ""), do: street_list ++ []
  defp get_building(street_list, building), do: street_list ++ [building]

  defp get_street_part("", _street_type, _building), do: []
  defp get_street_part(street, street_type, building) do
    []
    |> get_street_type(street_type)
    |> get_street(street)
    |> get_building(building)
    |> Enum.join(" ")
    |> get_street_part()
  end
  defp get_street_part(""), do: []
  defp get_street_part(street_part), do: [street_part]

  defp get_settlement_type(settlement_list, ""), do: settlement_list ++ []
  defp get_settlement_type(settlement_list, settlement_type), do: settlement_list ++ [settlement_type]

  defp get_settlement(settlement_list, ""), do: settlement_list ++ []
  defp get_settlement(settlement_list, settlement), do: settlement_list ++ [settlement]

  defp get_settlement_building(settlement_list, [], building), do: settlement_list ++ [building]
  defp get_settlement_building(settlement_list, _street_part, _building), do: settlement_list ++ []

  defp get_settlement_part("", _settlement_type, _street_part, _building), do: []
  defp get_settlement_part(settlement, settlement_type, street_part, building) do
    []
    |> get_settlement_type(settlement_type)
    |> get_settlement(settlement)
    |> get_settlement_building(street_part, building)
    |> Enum.join(" ")
    |> get_settlement_part()
  end
  defp get_settlement_part(""), do: []
  defp get_settlement_part(settlement_part), do: [settlement_part]

  defp get_apartment(""), do: []
  defp get_apartment(apartment), do: ["квартира " <> apartment]

  defp get_zip(""), do: []
  defp get_zip(zip), do: [zip]
end
