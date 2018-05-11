defmodule EHealth.Unit.LegalEntityTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox
  import Ecto.Query, warn: false

  alias Ecto.UUID
  alias EHealth.{Repo, PRMRepo}
  alias EHealth.EmployeeRequests.EmployeeRequest
  alias EHealth.LegalEntities, as: API
  alias EHealth.LegalEntities.{Validator, LegalEntity}

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
        |> Base.encode64()

      assert {:ok, _} =
               Validator.validate_sign_content(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => content
                 },
                 [{"edrpou", "37367387"}]
               )
    end

    test "invalid signed content validation" do
      assert %Ecto.Changeset{valid?: false} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base256",
                   "signed_legal_entity_request" => "invalid"
                 },
                 []
               )
    end

    test "can process 424 error" do
      error = %{
        "error" => %{
          "message" =>
            "The method could not be performed on the resource because the requested action depended on another action and that action failed.",
          "type" => "failed_dependency"
        },
        "meta" => %{
          "code" => 424,
          "request_id" => "2kmadsntegh08ugvek000ef2",
          "type" => "object",
          "url" => "http://www.example.com/digital_signatures"
        }
      }

      assert %Ecto.Changeset{valid?: false} = Validator.normalize_signature_error({:error, error})
    end

    test "invalid signed content - 2 signers" do
      content = get_legal_entity_data()

      signatures = [
        %{"is_valid" => true, "signer" => %{}, "validation_error_message" => ""},
        %{"is_valid" => true, "signer" => %{}, "validation_error_message" => ""}
      ]

      {:error, {:bad_request, "document must be signed by 1 signer but contains 2 signatures"}} =
        Validator.validate_json({:ok, %{"data" => %{"content" => content, "signatures" => signatures}}})
    end

    test "invalid signed content - no security" do
      content = get_legal_entity_data() |> Map.delete("security")

      signatures = [%{"is_valid" => true, "signer" => %{}, "validation_error_message" => ""}]

      {:error, [{error, _}]} =
        Validator.validate_json({:ok, %{"data" => %{"content" => content, "signatures" => signatures}}})

      assert :required == error[:rule]
      assert "required property security was not present" == error[:description]
    end

    test "invalid signed content - birth date format" do
      content =
        "test/data/signed_content_invalid_owner_birth_date.json"
        |> File.read!()
        |> Base.encode64()

      assert {:error, [_, {error, entry}]} =
               Validator.decode_and_validate(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => content
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

    test "validate legal entity with not allowed kved", %{conn: conn} do
      kveds = %{
        "name" => "KVEDS",
        "values" => %{
          "21.20": "Виробництво фармацевтичних препаратів і матеріалів"
        },
        "labels" => ["SYSTEM", "EXTERNAL"],
        "is_active" => true
      }

      patch(conn, dictionary_path(conn, :update, "KVEDS"), kveds)

      content =
        Map.merge(get_legal_entity_data(), %{
          "short_name" => "Nebo15",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      request = %{"data" => %{"content" => content}}

      assert %Ecto.Changeset{valid?: false} =
               API.create(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => request
                 },
                 []
               )
    end

    test "validate decoded legal entity" do
      content = get_legal_entity_data()

      assert :ok == Validator.validate_schema(content)
    end

    test "validate legal entity EDRPOU" do
      content = get_legal_entity_data()

      signer = %{"edrpou" => "37367387"}

      assert {:ok, _} = Validator.validate_edrpou(content, signer)
    end

    test "empty signer EDRPOU" do
      content = get_legal_entity_data()

      signer = %{"empty" => "37367387"}

      assert {:error, %Ecto.Changeset{valid?: false}} = Validator.validate_edrpou(content, signer)
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

      expect(ManMock, :render_template, fn _id, _data ->
        {:ok, "<html><body>Printout form for declaration request.</body></html>"}
      end)

      :ok
    end

    test "mis_verified NOT_VERIFIED" do
      data =
        Map.merge(get_legal_entity_data(), %{
          "short_name" => "Nebo15",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      params =
        data
        |> Map.get("addresses", [])
        |> Enum.at(0)
        |> Map.take(~w(settlement_id region_id district_id area))

      uaddresses_mock_expect(params)

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(data)

      # test legal entity data
      assert "Nebo15" == legal_entity.short_name
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
      data =
        Map.merge(get_legal_entity_data(), %{
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      params =
        data
        |> Map.get("addresses", [])
        |> Enum.at(0)
        |> Map.take(~w(settlement_id region_id district_id area))

      uaddresses_mock_expect(params)

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

      expect(ManMock, :render_template, fn _id, _data ->
        {:ok, "<html><body>Printout form for declaration request.</body></html>"}
      end)

      :ok
    end

    test "happy path" do
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "10002000")
      insert(:prm, :legal_entity, edrpou: "37367387")

      update_data =
        Map.merge(get_legal_entity_data(), %{
          "edrpou" => "37367387",
          "short_name" => "Nebo15",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      params =
        update_data
        |> Map.get("addresses", [])
        |> Enum.at(0)
        |> Map.take(~w(settlement_id region_id district_id area))

      uaddresses_mock_expect(params)

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(update_data)

      assert "37367387" == legal_entity.edrpou
      assert "ACTIVE" == legal_entity.status
      assert "VERIFIED" == legal_entity.mis_verified
      assert "changed@example.com" == legal_entity.email
      assert "Nebo15" == legal_entity.short_name
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
      insert(:prm, :legal_entity, edrpou: "37367387", is_active: false)

      data = Map.merge(get_legal_entity_data(), %{"edrpou" => "37367387"})

      params =
        data
        |> Map.get("addresses", [])
        |> Enum.at(0)
        |> Map.take(~w(settlement_id region_id district_id area))

      uaddresses_mock_expect(params)

      assert {:ok, %{legal_entity: legal_entity}} = create_legal_entity(data)
      assert true = legal_entity.is_active
    end
  end

  test "CLOSED Legal Entity cannot be updated" do
    insert_dictionaries()
    legal_entity = insert(:prm, :legal_entity, edrpou: "37367387", status: "CLOSED")

    params =
      legal_entity
      |> Map.get(:addresses, [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area)a)
      |> convert_atom_keys_to_strings()

    uaddresses_mock_expect(params)

    assert {:error, {:conflict, "LegalEntity can't be updated"}} == create_legal_entity(get_legal_entity_data())
  end

  describe "update Legal Entity with OPS contract suspend" do
    test "successfully update name" do
      expect(ManMock, :render_template, fn _id, _data ->
        {:ok, "<html><body>Printout form for declaration request.</body></html>"}
      end)

      expect(OPSMock, :get_contracts, fn _params, _headers ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}, %{"id" => UUID.generate()}]}}
      end)

      expect(OPSMock, :suspend_contracts, fn ids, _headers ->
        assert 2 == length(ids)
        {:ok, %{"data" => %{"suspended" => 2}}}
      end)

      insert_dictionaries()
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "37367387")

      update_data = Map.merge(get_legal_entity_data(), %{"name" => "Нова"})

      params =
        update_data
        |> Map.get("addresses", [])
        |> Enum.at(0)
        |> Map.take(~w(settlement_id region_id district_id area))

      uaddresses_mock_expect(params)

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

    test "OPS get_contracts respond with invalid data" do
      expect(OPSMock, :get_contracts, fn _params, _headers ->
        {:ok, %{"data" => "invalid format"}}
      end)

      legal_entity = insert(:prm, :legal_entity, name: "New Line")
      changeset = API.changeset(legal_entity, %{"name" => "New World"})

      assert {:error, {:service_unavailable, "Cannot suspend contracts. Try later"}} =
               API.transaction_update_with_ops_contract(changeset, [])
    end

    test "OPS suspend_contracts respond with invalid data" do
      expect(OPSMock, :get_contracts, fn _params, _headers ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}, %{"id" => UUID.generate()}]}}
      end)

      expect(OPSMock, :suspend_contracts, fn _ids, _headers ->
        {:ok, %{"data" => "invalid format"}}
      end)

      legal_entity = insert(:prm, :legal_entity, name: "New Line")
      changeset = API.changeset(legal_entity, %{"name" => "New World"})

      assert {:error, {:service_unavailable, "Cannot suspend contracts. Try later"}} =
               API.transaction_update_with_ops_contract(changeset, [])
    end

    test "rollback suspended contracts on failed contracts suspending" do
      contract_id_1 = UUID.generate()
      contract_id_2 = UUID.generate()
      legal_entity = insert(:prm, :legal_entity, name: "New Line")

      expect(OPSMock, :get_contracts, fn params, _headers ->
        Enum.each(~w(legal_entity_id status is_suspended)a, fn key ->
          assert Map.has_key?(params, key), "OPS.get_contracts requires param `#{key}` in `#{inspect(params)}`"
        end)

        assert params.legal_entity_id == legal_entity.id
        assert params.status == "VERIFIED"
        assert params.is_suspended == false

        {:ok, %{"data" => [%{"id" => contract_id_1}, %{"id" => contract_id_2}]}}
      end)

      # not all contracts was suspended
      expect(OPSMock, :suspend_contracts, fn ids, _headers ->
        assert 2 = length(ids)
        assert contract_id_1 in ids
        assert contract_id_2 in ids
        {:ok, %{"data" => %{"suspended" => 1}}}
      end)

      expect(OPSMock, :renew_contracts, fn ids, _headers ->
        assert 2 = length(ids)
        assert contract_id_1 in ids
        assert contract_id_2 in ids
        {:ok, %{"data" => %{}}}
      end)

      changeset = API.changeset(legal_entity, %{"name" => "New World"})

      assert {:error, {:service_unavailable, "Cannot suspend contracts. Try later"}} =
               API.transaction_update_with_ops_contract(changeset, [])
    end

    test "rollback suspended contracts on legal entity update when edrpou is duplicated" do
      insert(:prm, :legal_entity, edrpou: "10020030")
      legal_entity = insert(:prm, :legal_entity)

      expect(OPSMock, :get_contracts, fn _params, _headers ->
        {:ok, %{"data" => [%{"id" => UUID.generate()}, %{"id" => UUID.generate()}]}}
      end)

      # not all contracts was suspended
      expect(OPSMock, :suspend_contracts, fn ids, _headers ->
        {:ok, %{"data" => %{"suspended" => length(ids)}}}
      end)

      expect(OPSMock, :renew_contracts, fn _ids, _headers ->
        {:ok, %{"data" => %{}}}
      end)

      changeset = API.changeset(legal_entity, %{"edrpou" => "10020030"})

      assert {:error, %Ecto.Changeset{valid?: false}} = API.transaction_update_with_ops_contract(changeset, [])
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

    expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
      get_settlement(
        %{
          "id" => Map.get(List.first(content["addresses"]), "settlement_id"),
          "region_id" => Map.get(List.first(content["addresses"]), "region_id"),
          "district_id" => Map.get(List.first(content["addresses"]), "district_id")
        },
        200
      )
    end)

    assert {:error,
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses.settlement"}]} ==
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

    expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
      get_settlement(%{}, 200)
    end)

    assert {:error,
            [{%{description: "invalid settlement value", params: [], rule: :invalid}, "$.addresses.settlement"}]} ==
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

    district_id = UUID.generate()

    params =
      legal_entity_data
      |> Map.get("addresses", [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))
      |> Map.put("district_id", district_id)

    uaddresses_mock_expect(params)

    expect(UAddressesMock, :get_district_by_id, fn _id, _headers ->
      get_region(%{"id" => district_id, "name" => "test"}, 200)
    end)

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses.region"}]} ==
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

    district_id = UUID.generate()

    params =
      legal_entity_data
      |> Map.get("addresses", [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))
      |> Map.put("district_id", district_id)

    uaddresses_mock_expect(params)

    expect(UAddressesMock, :get_district_by_id, fn _id, _headers ->
      get_region(%{"id" => district_id, "name" => "test"}, 200)
    end)

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid}, "$.addresses.region"}]} ==
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

    params =
      legal_entity_data
      |> Map.get("addresses", [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))

    uaddresses_mock_expect(params)

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses.area"}]} ==
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

    params =
      legal_entity_data
      |> Map.get("addresses", [])
      |> Enum.at(0)
      |> Map.take(~w(settlement_id region_id district_id area))

    uaddresses_mock_expect(params)

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid}, "$.addresses.area"}]} ==
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
      {"x-consumer-id", Ecto.UUID.generate()},
      {"edrpou", "37367387"}
    ]
  end

  defp create_legal_entity(request_params) do
    request = %{
      "signed_legal_entity_request" => Base.encode64(Poison.encode!(request_params)),
      "signed_content_encoding" => "base64"
    }

    API.create(request, get_headers())
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Poison.decode!()
  end

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_address_type)
    insert(:il, :dictionary_document_type)
  end

  defp uaddresses_mock_expect(params) do
    expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
      get_settlement(
        %{
          "id" => params["settlement_id"],
          "region_id" => params["region_id"],
          "district_id" => params["district_id"]
        },
        200
      )
    end)

    expect(UAddressesMock, :get_region_by_id, fn _id, _headers ->
      get_region(%{"id" => params["region_id"], "name" => params["area"]}, 200)
    end)
  end

  defp get_settlement(params, response_status, mountain_group \\ false) do
    settlement =
      %{
        "id" => UUID.generate(),
        "region_id" => UUID.generate(),
        "district_id" => UUID.generate(),
        "name" => "Київ",
        "mountain_group" => mountain_group
      }
      |> Map.merge(params)

    {:ok, %{"data" => settlement, "meta" => %{"code" => response_status}}}
  end

  def get_region(params, response_status) do
    region =
      %{
        "id" => UUID.generate(),
        "name" => "Львівська"
      }
      |> Map.merge(params)

    {:ok, %{"data" => region, "meta" => %{"code" => response_status}}}
  end
end
