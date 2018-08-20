defmodule Core.Unit.AddressMergerTest do
  @moduledoc false

  use Core.ConnCase

  alias Core.Dictionaries
  alias Core.Utils.AddressMerger

  setup do
    Dictionaries.create_dictionary(%{
      name: "SETTLEMENT_TYPE",
      labels: [],
      values: %{CITY: "місто", VILLAGE: "село"}
    })

    Dictionaries.create_dictionary(%{
      name: "STREET_TYPE",
      labels: [],
      values: %{STREET: "вулиця"}
    })

    :ok
  end

  test "merging nil address" do
    assert "" == AddressMerger.merge_address(nil)
  end

  test "merging address with all fields" do
    result =
      AddressMerger.merge_address(%{
        "area" => "Херсонська",
        "region" => "Дніпровський",
        "settlement_type" => "CITY",
        "settlement" => "Херсон",
        "street_type" => "STREET",
        "street" => "Вокзальна",
        "building" => "1",
        "apartment" => "1",
        "zip" => "12345"
      })

    assert "Херсонська область, Дніпровський район, місто Херсон, вулиця Вокзальна 1, квартира 1, 12345" == result
  end

  test "merging address without street" do
    result =
      AddressMerger.merge_address(%{
        "area" => "Херсонська",
        "region" => "Скадовський",
        "settlement_type" => "VILLAGE",
        "settlement" => "Андріївка",
        "building" => "1",
        "apartment" => "1",
        "zip" => "12345"
      })

    assert "Херсонська область, Скадовський район, село Андріївка 1, квартира 1, 12345" == result
  end

  test "merging address with no suffix area" do
    result =
      AddressMerger.merge_address(%{
        "area" => "м.Київ",
        "settlement_type" => "CITY",
        "settlement" => "Київ",
        "street_type" => "STREET",
        "street" => "Вокзальна",
        "building" => "1",
        "apartment" => "1",
        "zip" => "12345"
      })

    assert "м.Київ, місто Київ, вулиця Вокзальна 1, квартира 1, 12345" == result
  end

  test "merging address with no fields" do
    assert "" == AddressMerger.merge_address(%{})
  end
end
