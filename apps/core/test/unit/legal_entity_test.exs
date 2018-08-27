defmodule Core.Unit.LegalEntityTest do
  @moduledoc false

  use Core.ConnCase, async: false

  import Core.Expectations.Man
  import Core.Expectations.Signature
  import Ecto.Query, warn: false
  import Mox

  alias Core.EmployeeRequests.EmployeeRequest
  alias Core.LegalEntities, as: API
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.Validator
  alias Core.PRMRepo
  alias Core.Repo
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

      expect(UAddressesMock, :validate_addresses, fn _, _ ->
        {:ok, %{"data" => %{}}}
      end)

      assert {:ok, _} =
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
                   params: ["base64"],
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
                   description: "document must be signed by 1 signer but contains 2 signatures",
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
      assert {:ok, _} = Validator.validate_edrpou(content, signer)
    end

    test "validate legal entity DRFO int" do
      content = get_legal_entity_data()
      drfo = "2856209537"
      signer = %{"drfo" => drfo}

      assert {:ok, _} =
               content
               |> Map.put("edrpou", drfo)
               |> Validator.validate_edrpou(signer)
    end

    test "validate legal entity DRFO text not allowed" do
      content = get_legal_entity_data()
      drfo = "ЁЇ756475"
      signer = %{"drfo" => drfo}

      assert {:error, _} =
               content
               |> Map.put("edrpou", "Ёї756475")
               |> Validator.validate_edrpou(signer)
    end

    test "invalid legal entity DRFO text" do
      content = get_legal_entity_data()
      drfo = "їҐ12345"
      signer = %{"drfo" => drfo}

      assert {:error, %Ecto.Changeset{valid?: false}} =
               content
               |> Map.put("edrpou", drfo)
               |> Validator.validate_edrpou(signer)
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

      Validator.validate_edrpou(content, signer)
    end

    test "invalid signer EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"edrpou" => "03736738"}
      assert {:error, %Ecto.Changeset{valid?: false}} = Validator.validate_edrpou(content, signer)
    end

    test "different signer EDRPOU" do
      content = get_legal_entity_data()
      signer = %{"edrpou" => "0373167387"}
      assert {:error, %Ecto.Changeset{valid?: false}} = Validator.validate_edrpou(content, signer)
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

    test "mis_verified NOT_VERIFIED" do
      put_client()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      template()

      data =
        Map.merge(get_legal_entity_data(), %{
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      uaddresses_mock_expect()
      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(data)

      # test legal entity data
      assert "edenlab" == legal_entity.short_name
      assert "ACTIVE" == legal_entity.status
      assert "NOT_VERIFIED" == legal_entity.mis_verified
      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified
      assert_security(security, legal_entity.id)

      # test employee request
      assert 1 == Repo.one(from(e in EmployeeRequest, select: count("*")))
      assert %EmployeeRequest{data: employee_request_data, status: "NEW"} = Repo.one(from(e in EmployeeRequest))
      assert legal_entity.id == employee_request_data["legal_entity_id"]
      assert "P1" == employee_request_data["position"]
      assert "OWNER" == employee_request_data["employee_type"]

      assert 1 == PRMRepo.one(from(l in LegalEntity, select: count("*")))
    end

    test "mis_verified VERIFIED" do
      put_client()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      template()

      data =
        Map.merge(get_legal_entity_data(), %{
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      uaddresses_mock_expect()
      insert(:prm, :registry, edrpou: "37367387", type: LegalEntity.type(:msp))

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(data)
      # test legal entity data
      assert "edenlab" == legal_entity.short_name
      assert "ACTIVE" == legal_entity.status
      assert "VERIFIED" == legal_entity.mis_verified
      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified
      assert_security(security, legal_entity.id)

      # test employee request
      assert 1 == Repo.one(from(e in EmployeeRequest, select: count("*")))
      assert %EmployeeRequest{data: employee_request_data, status: "NEW"} = Repo.one(from(e in EmployeeRequest))
      assert legal_entity.id == employee_request_data["legal_entity_id"]
      assert "P1" == employee_request_data["position"]
      assert "OWNER" == employee_request_data["employee_type"]

      assert 1 == PRMRepo.one(from(l in LegalEntity, select: count("*")))
    end
  end

  describe "update Legal Entity" do
    setup _context do
      insert_dictionaries()
      template()
      :ok
    end

    test "happy path" do
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "10002000")
      insert(:prm, :legal_entity, edrpou: "37367387")
      put_client()

      update_data =
        Map.merge(get_legal_entity_data(), %{
          "edrpou" => "37367387",
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      uaddresses_mock_expect()
      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(update_data)

      assert "37367387" == legal_entity.edrpou
      assert "ACTIVE" == legal_entity.status
      assert "VERIFIED" == legal_entity.mis_verified
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

    test "update inactive Legal Entity" do
      put_client()
      insert(:prm, :legal_entity, edrpou: "37367387", is_active: false)

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      data = Map.merge(get_legal_entity_data(), %{"edrpou" => "37367387"})
      uaddresses_mock_expect()
      assert {:ok, %{legal_entity: legal_entity}} = create_legal_entity(data)
      assert true = legal_entity.is_active
    end
  end

  test "CLOSED Legal Entity cannot be updated" do
    insert_dictionaries()
    insert(:prm, :legal_entity, edrpou: "37367387", status: "CLOSED")
    uaddresses_mock_expect()
    assert {:error, {:conflict, "LegalEntity can't be updated"}} == create_legal_entity(get_legal_entity_data())
  end

  describe "update Legal Entity with OPS contract suspend" do
    test "successfully update name" do
      put_client()
      template()

      expect(MithrilMock, :get_client_type_by_name, fn _, _ ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}]}}
      end)

      insert_dictionaries()
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "37367387")

      update_data = Map.merge(get_legal_entity_data(), %{"name" => "Нова"})
      uaddresses_mock_expect()
      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(update_data)

      assert "Нова" == legal_entity.name
      assert "ACTIVE" == legal_entity.status

      assert_security(security, legal_entity.id)
      assert 1 == PRMRepo.one(from(l in LegalEntity, select: count("*")))

      qry = "SELECT changeset FROM audit_log WHERE resource = 'legal_entities'"

      # check that audit_log created in transaction
      assert %{num_rows: 1, rows: [[row]]} = Ecto.Adapters.SQL.query!(PRMRepo, qry, [])
      assert "Нова" == row["name"]
    end

    test "rollback suspended contracts on legal entity update when edrpou is duplicated" do
      insert(:prm, :legal_entity, edrpou: "10020030")
      legal_entity = insert(:prm, :legal_entity)
      changeset = API.changeset(legal_entity, %{"edrpou" => "10020030"})
      assert {:error, %Ecto.Changeset{valid?: false}} = API.transaction_update_with_contract(changeset, [])
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
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses[0].settlement"}]} ==
             Validator.validate_addresses(content, [])
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
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses[0].settlement"}]} ==
             Validator.validate_addresses(content, [])
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

    uaddresses_invalid_mock("$.addresses[0].region", "invalid region value")

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses[0].region"}]} ==
             Validator.validate_addresses(content, [])
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

    uaddresses_invalid_mock("$.addresses[0].region", "invalid region value")

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses[0].region"}]} ==
             Validator.validate_addresses(content, [])
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

    uaddresses_invalid_mock("$.addresses[0].area", "invalid area value")

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses[0].area"}]} ==
             Validator.validate_addresses(content, [])
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

    uaddresses_invalid_mock("$.addresses[0].area", "invalid area value")

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses[0].area"}]} ==
             Validator.validate_addresses(content, [])
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
      {"edrpou", "37367387"}
    ]
  end

  defp create_legal_entity(request_params) do
    request = %{
      "signed_legal_entity_request" => Base.encode64(Jason.encode!(request_params)),
      "signed_content_encoding" => "base64"
    }

    edrpou_signed_content(request_params, "37367387")
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

  defp uaddresses_mock_expect do
    expect(UAddressesMock, :validate_addresses, fn _, _ ->
      {:ok, %{"data" => %{}}}
    end)
  end

  defp uaddresses_invalid_mock(path \\ "$.addresses[0].settlement", message \\ "invalid settlement value") do
    expect(UAddressesMock, :validate_addresses, fn _, _ ->
      {:error,
       %{
         "error" => %{
           "invalid" => [
             %{
               "entry" => path,
               "entry_type" => "json_data_property",
               "rules" => [
                 %{"description" => message, "params" => []}
               ]
             }
           ]
         }
       }}
    end)
  end
end
