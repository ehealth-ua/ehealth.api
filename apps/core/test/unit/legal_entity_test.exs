defmodule Core.Unit.LegalEntityTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Core.Expectations.Man
  import Core.Expectations.Signature
  import Ecto.Query, warn: false
  import Mox

  alias Core.LegalEntities, as: API
  alias Core.LegalEntities.EdrData
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Validator
  alias Core.PRMRepo
  alias Ecto.Changeset
  alias Ecto.UUID

  setup :verify_on_exit!

  describe "validations" do
    setup _context do
      insert_dictionaries()
      :ok
    end

    test "successed signed content validation" do
      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      edrpou_signed_content(content, "38782323")
      expect_uaddresses_validate()

      assert {:ok, _, %{edrpou: "38782323"}} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => Jason.encode!(content)
                 },
                 [{"edrpou", "38782323"}]
               )
    end

    test "invalid signed content validation" do
      assert {:error,
              [
                {%{
                   description: "value is not allowed in enum",
                   params: %{values: ["base64"]},
                   rule: :inclusion
                 }, "$.signed_content_encoding"}
              ]} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base256",
                   "signed_legal_entity_request" => "invalid"
                 },
                 []
               )
    end

    test "invalid signed content - 2 signers" do
      content = get_legal_entity_data()

      request = %{
        "signed_legal_entity_request" => Base.encode64(Jason.encode!(content)),
        "signed_content_encoding" => "base64"
      }

      edrpou_signed_content(content, ["37367387", "37367387"])

      assert {:error,
              [
                {%{
                   description: "document must contain 1 signature and 0 stamps but contains 2 signatures and 0 stamps",
                   params: [],
                   rule: :invalid
                 }, "$.signed_legal_entity_request"}
              ]} == Validator.decode_and_validate(request, [])
    end

    test "invalid signed content - birth date format" do
      content = File.read!("test/data/signed_content_invalid_owner_birth_date.json")
      edrpou_signed_content(Jason.decode!(content), "37367387")

      assert {:error, [_, {error, entry}]} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => Base.encode64(content)
                 },
                 []
               )

      assert "$.owner.birth_date" == entry
      assert :format == error[:rule]
    end

    test "invalid signed content - not a base 64 string" do
      content = File.read!("test/data/signed_content_invalid_owner_birth_date.json")
      invalid_signed_content()

      assert {:error, [{error, entry}]} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => content
                 },
                 []
               )

      assert "$.signed_legal_entity_request" == entry
      assert :invalid == error[:rule]
      assert %{description: "Not a base64 string"} = error
    end

    test "invalid signed content - invalid json format" do
      content = "{test: test test}"
      invalid_signed_content_json_format()

      assert {:error, [{error, entry}]} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => Base.encode64(content)
                 },
                 []
               )

      assert "$.signed_legal_entity_request" == entry
      assert :invalid == error[:rule]
      assert error.description =~ "you have encoded corrupted JSON"
    end

    test "invalid tax id" do
      content = %{"owner" => %{"tax_id" => "00000000"}}
      assert {:error, [{error, entry}]} = Validator.validate_tax_id(content)
      assert "$.owner.tax_id" == entry
      assert :invalid == error[:rule]

      content = %{"owner" => %{"tax_id" => "00000000", "no_tax_id" => false}}
      assert {:error, [{error, entry}]} = Validator.validate_tax_id(content)
      assert "$.owner.tax_id" == entry
      assert :invalid == error[:rule]
    end

    test "no_tax_id is true" do
      content = %{"owner" => %{"tax_id" => "00000000", "no_tax_id" => true}}
      assert {:error, [{error, entry}]} = Validator.validate_tax_id(content)
      assert "$.owner.no_tax_id" == entry
      assert :invalid == error[:rule]
    end

    test "validate legal entity EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"edrpou" => "37367387"}
      assert {:ok, %{edrpou: "37367387"}} = Validator.validate_state_registry_number(content, signer)
    end

    test "validate legal entity DRFO int" do
      content = get_legal_entity_data()
      drfo = "2856209537"
      signer = %{"drfo" => drfo}

      assert {:ok, %{drfo: drfo}} =
               content
               |> Map.put("edrpou", drfo)
               |> Validator.validate_state_registry_number(signer)
    end

    test "validate legal entity DRFO text not allowed" do
      content = get_legal_entity_data()
      drfo = "ЁЇ756475"
      signer = %{"drfo" => drfo}

      assert {:error, _} =
               content
               |> Map.put("edrpou", "Ёї756475")
               |> Validator.validate_state_registry_number(signer)
    end

    test "invalid legal entity DRFO text" do
      content = get_legal_entity_data()
      drfo = "їҐ12345"
      signer = %{"drfo" => drfo}

      assert {:error, %Changeset{valid?: false}} =
               content
               |> Map.put("edrpou", drfo)
               |> Validator.validate_state_registry_number(signer)
    end

    test "empty signer EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"empty" => "37367387"}

      assert {:error,
              [
                {%{
                   description: "EDRPOU and DRFO is empty in digital sign",
                   rule: :invalid
                 }, "$.data"}
              ]}

      Validator.validate_state_registry_number(content, signer)
    end

    test "invalid signer EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"edrpou" => "03736738"}
      assert {:error, %Changeset{valid?: false}} = Validator.validate_state_registry_number(content, signer)
    end

    test "different signer EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"edrpou" => "0373167387"}
      assert {:error, %Changeset{valid?: false}} = Validator.validate_state_registry_number(content, signer)
    end
  end

  describe "create new Legal Entity" do
    setup _context do
      insert_dictionaries()

      :ok
    end

    test "create Legal Entity with invalid type" do
      invalid_legal_entity_type = "MIS"
      data = Map.merge(get_legal_entity_data(), %{"type" => invalid_legal_entity_type})

      assert {
               :error,
               {:"422", "Only legal_entity with type MSP or Pharmacy could be created"}
             } = create_legal_entity(data)
    end

    test "success new legal entity and new edr_data" do
      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      put_client()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      expect_uaddresses_validate()
      upsert_client_connection()

      edr_id = DateTime.to_unix(DateTime.utc_now())

      expect_search_legal_entity(
        {:ok,
         [
           %{
             "id" => edr_id,
             "state" => 1
           }
         ]}
      )

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => edr_id,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"name" => content["name"], "display" => content["name"]},
           "olf_code" => content["legal_form"],
           "activity_kinds" => [
             %{
               "name" => "Оптова торгівля комп'ютерами, периферійним устаткованням і програмним забезпеченням",
               "code" => "46.51",
               "is_primary" => false
             }
           ],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})
      template()

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(content)
      assert "38782323" == legal_entity.edrpou
      assert LegalEntity.status(:active) == legal_entity.status
      assert content["email"] == legal_entity.email
      assert content["short_name"] == legal_entity.short_name

      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified

      assert_security(security, legal_entity.id)
      assert %LegalEntity{} = PRMRepo.get(LegalEntity, legal_entity.id)
      assert %EdrData{} = PRMRepo.get(EdrData, legal_entity.edr_data_id)
    end

    test "success new legal entity with existing edr_data" do
      edr_id = DateTime.to_unix(DateTime.utc_now())
      edr_data = insert(:prm, :edr_data, edr_id: edr_id)

      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      put_client()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      expect_uaddresses_validate()
      upsert_client_connection()

      expect_search_legal_entity(
        {:ok,
         [
           %{
             "id" => edr_id,
             "state" => 1
           }
         ]}
      )

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => edr_id,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"name" => content["name"], "display" => content["name"]},
           "olf_code" => content["legal_form"],
           "activity_kinds" => [
             %{
               "name" => "Оптова торгівля комп'ютерами, периферійним устаткованням і програмним забезпеченням",
               "code" => "46.51",
               "is_primary" => false
             }
           ],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})
      template()

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(content)
      assert "38782323" == legal_entity.edrpou
      assert LegalEntity.status(:active) == legal_entity.status
      assert content["email"] == legal_entity.email
      assert content["short_name"] == legal_entity.short_name

      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified

      edr_data_id = edr_data.id
      assert_security(security, legal_entity.id)
      assert %LegalEntity{edr_data_id: ^edr_data_id} = PRMRepo.get(LegalEntity, legal_entity.id)
      assert %EdrData{edr_id: ^edr_id} = PRMRepo.get(EdrData, legal_entity.edr_data_id)
    end

    test "success new legal entity with existing closed edr_data and new active edr_data from edr" do
      edr_data = insert(:prm, :edr_data, state: 0, legal_entities: [])
      edr_id = DateTime.to_unix(DateTime.utc_now())

      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      put_client()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      expect_uaddresses_validate()
      upsert_client_connection()

      expect_search_legal_entity(
        {:ok,
         [
           %{
             "id" => edr_data.edr_id,
             "state" => 0
           },
           %{
             "id" => edr_id,
             "state" => 1
           }
         ]}
      )

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => edr_id,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"name" => content["name"], "display" => content["name"]},
           "olf_code" => content["legal_form"],
           "activity_kinds" => [
             %{
               "name" => "Оптова торгівля комп'ютерами, периферійним устаткованням і програмним забезпеченням",
               "code" => "46.51",
               "is_primary" => false
             }
           ],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})
      template()

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(content)
      assert "38782323" == legal_entity.edrpou
      assert LegalEntity.status(:active) == legal_entity.status
      assert content["email"] == legal_entity.email
      assert content["short_name"] == legal_entity.short_name

      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified

      edr_data_id = edr_data.id
      assert_security(security, legal_entity.id)
      assert %LegalEntity{edr_data_id: ^edr_data_id} = PRMRepo.get(LegalEntity, legal_entity.id)
      assert %EdrData{edr_id: ^edr_id} = PRMRepo.get(EdrData, legal_entity.edr_data_id)
    end

    test "fail to create new legal entity with invalid edr response" do
      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      expect_uaddresses_validate()
      expect_search_legal_entity({:error, :timeout})

      assert {:error, {:conflict, "Legal Entity not found in EDR"}} = create_legal_entity(content)
    end

    test "fail to create new legal entity with inactive legal entities with references to closed edr_data" do
      edr_data =
        insert(:prm, :edr_data,
          state: 1,
          legal_entities: [build(:legal_entity, status: LegalEntity.status(:suspended))]
        )

      edr_id = DateTime.to_unix(DateTime.utc_now())

      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      expect_uaddresses_validate()

      expect_search_legal_entity(
        {:ok,
         [
           %{"id" => edr_data.edr_id, "state" => 0},
           %{"id" => edr_id, "state" => 1}
         ]}
      )

      assert {:error,
              [
                {%{
                   description: "Legal entity with such edrpou and type already exists",
                   params: [],
                   rule: :invalid
                 }, "$.data.edrpou"}
              ]} = create_legal_entity(content)
    end

    test "fail to create new legal entity with closed edr_data from edr" do
      edr_id = DateTime.to_unix(DateTime.utc_now())

      content =
        "test/data/signed_content.json"
        |> File.read!()
        |> Jason.decode!()

      expect_uaddresses_validate()

      expect_search_legal_entity(
        {:ok,
         [
           %{
             "id" => edr_id,
             "state" => 0
           }
         ]}
      )

      assert {:error,
              [
                {%{
                   description: "Provided EDRPOU is not active in EDR",
                   params: [],
                   rule: :invalid
                 }, "$.data.edrpou"}
              ]} = create_legal_entity(content)
    end
  end

  describe "update Legal Entity" do
    setup _context do
      insert_dictionaries()
      :ok
    end

    test "success update legal entity references active edr_data" do
      insert(:prm, :registry)
      insert(:prm, :edr_data)
      put_client()

      update_data =
        Map.merge(get_legal_entity_data(), %{
          "edrpou" => "38782323",
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["86.10"]
        })

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      expect_uaddresses_validate()
      upsert_client_connection()

      edr_id = DateTime.to_unix(DateTime.utc_now())

      expect_search_legal_entity(
        {:ok,
         [
           %{
             "id" => edr_id,
             "state" => 1
           }
         ]}
      )

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => edr_id,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"name" => update_data["name"], "display" => update_data["name"]},
           "olf_code" => update_data["legal_form"],
           "activity_kinds" => [
             %{
               "name" => "Оптова торгівля комп'ютерами, периферійним устаткованням і програмним забезпеченням",
               "code" => "46.51",
               "is_primary" => false
             }
           ],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})
      template()

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(update_data)

      assert "38782323" == legal_entity.edrpou
      assert LegalEntity.status(:active) == legal_entity.status
      assert "changed@example.com" == legal_entity.email
      assert "edenlab" == legal_entity.short_name
      assert "Лев Томас" == legal_entity.beneficiary

      assert [
               %{
                 "date" => "2012-12-29",
                 "place" => "Житомир вул. Малярів, буд. 211, корп. 2, оф. 1"
               }
             ] == legal_entity.archive

      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified

      assert_security(security, legal_entity.id)
      assert %LegalEntity{} = PRMRepo.get(LegalEntity, legal_entity.id)
      assert 2 == PRMRepo.one(from(l in LegalEntity, select: count("*")))
    end

    test "fail to update legal_entity with invalid edr response" do
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "10002000")

      update_data =
        Map.merge(get_legal_entity_data(), %{
          "edrpou" => "38782323",
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["86.10"]
        })

      expect_uaddresses_validate()
      expect_search_legal_entity({:error, :timeout})

      assert {:error, {:conflict, "Legal Entity not found in EDR"}} = create_legal_entity(update_data)
    end
  end

  test "settlement validation with invalid settlement" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.put("settlement", "Новосілки")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock()

    assert {:error,
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses.[0].settlement"}]} ==
             Validator.validate_addresses(content)
  end

  test "settlement validation with empty settlement" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.delete("settlement")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock()

    assert {:error,
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses.[0].settlement"}]} ==
             Validator.validate_addresses(content)
  end

  test "region validation with invalid region" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.put("region", "Турійський")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock("$.addresses.[0].region", "invalid region value")

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses.[0].region"}]} ==
             Validator.validate_addresses(content)
  end

  test "region validation with empty region" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.delete("region")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock("$.addresses.[0].region", "invalid region value")

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses.[0].region"}]} ==
             Validator.validate_addresses(content)
  end

  test "area validation with invalid area" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.put("area", "Волинська")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock("$.addresses.[0].area", "invalid area value")

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses.[0].area"}]} ==
             Validator.validate_addresses(content)
  end

  test "area validation with empty area" do
    legal_entity_data = get_legal_entity_data()

    address =
      legal_entity_data
      |> Map.get("addresses")
      |> Enum.at(0)
      |> Map.delete("area")

    content =
      legal_entity_data
      |> Map.put("addresses", [address])

    uaddresses_invalid_mock("$.addresses.[0].area", "invalid area value")

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses.[0].area"}]} ==
             Validator.validate_addresses(content)
  end

  test "position validation with invalid position" do
    content = get_legal_entity_data() |> put_in(["owner", "position"], "P99")

    assert {:error, [{%{description: "invalid owner position value", params: [], rule: :invalid}, "$.owner.position"}]} ==
             Validator.validate_owner_position(content)
  end

  # helpers

  def assert_security(security, id) do
    assert Map.has_key?(security, "client_id")
    assert Map.has_key?(security, "client_secret")
    assert Map.has_key?(security, "redirect_uri")
    # security
    assert id == security["client_id"]
    refute nil == security["client_secret"]
    refute nil == security["redirect_uri"]
  end

  defp get_headers do
    [
      {"content-type", "application/json"},
      {"content-length", "7000"},
      {"x-consumer-id", UUID.generate()},
      {"edrpou", "38782323"}
    ]
  end

  defp create_legal_entity(request_params) do
    request = %{
      "signed_legal_entity_request" => Base.encode64(Jason.encode!(request_params)),
      "signed_content_encoding" => "base64"
    }

    edrpou_signed_content(request_params, "38782323")
    API.create(request, get_headers())
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_address_type)
    insert(:il, :dictionary_document_type)
  end

  defp uaddresses_invalid_mock(path \\ "$.addresses.[0].settlement", message \\ "invalid settlement value") do
    expect_uaddresses_validate(
      {:error,
       %{
         invalid: [
           %{
             entry: path,
             entry_type: "json_data_property",
             rules: [
               %{description: message, params: []}
             ]
           }
         ]
       }}
    )
  end
end
