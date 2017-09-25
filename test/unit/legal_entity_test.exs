defmodule EHealth.Unit.LegalEntityTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Ecto.Query, warn: false

  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.PRMRepo
  alias EHealth.Employee.Request, as: EmployeeRequest
  alias EHealth.LegalEntity.API
  alias EHealth.LegalEntity.Validator
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity

  test "successed signed content validation" do
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145")
    content = File.read!("test/data/signed_content.txt")

    assert {:ok, _} = Validator.validate_sign_content(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://localhost:4040")
  end

  test "invalid signed content validation" do
    assert %Ecto.Changeset{valid?: false} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base256",
      "signed_legal_entity_request" => "invalid"
    })
  end

  test "invalid signed content - no security" do
    content = get_legal_entity_data() |> Map.delete("security")

    assert {:error, [{error, _}]} = Validator.validate_json({:ok, %{"data" => %{"content" => content}}})
    assert :required == error[:rule]
    assert "required property security was not present" == error[:description]
  end

  test "invalid signed content - birth date format" do
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://35.187.186.145")
    content = File.read!("test/data/signed_content_invalid_owner_birth_date.txt")

    assert {:error, [_, {error, entry}]} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
    assert "$.owner.birth_date" == entry
    assert :format == error[:rule]
    System.put_env("DIGITAL_SIGNATURE_ENDPOINT", "http://localhost:4040")
  end

  test "invalid tax id" do
    content = %{"owner" => %{"tax_id" => "00000000"}}
    assert {:error, [{error, entry}]} = Validator.validate_tax_id(content)
    assert "$.owner.tax_id" == entry
    assert :invalid == error[:rule]
  end

  test "validate legal entity with not allowed kved", %{conn: conn} do
    kveds = %{
      "name" => "KVEDS",
      "values" => %{
        "21.20": "Виробництво фармацевтичних препаратів і матеріалів",
      },
      "labels" => ["SYSTEM", "EXTERNAL"],
      "is_active" => true,
    }
    patch conn, dictionary_path(conn, :update, "KVEDS"), kveds

    content = Map.merge(get_legal_entity_data(), %{
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })
    request = %{"data" => %{"content" => content}}

    assert %Ecto.Changeset{valid?: false} = API.create_legal_entity(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => request
    }, [])
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

  test "employee request start_date format" do
    %{"employee_request" => data} = API.prepare_employee_request_data(UUID.generate(), %{"position" => "лікар"})
    assert Map.has_key?(data, "start_date")
    assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, data["start_date"])
  end

  test "different signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "0373167387"}

    assert {:error, %Ecto.Changeset{valid?: false}} = Validator.validate_edrpou(content, signer)
  end

  describe "create new Legal Entity" do

    test "mis_verified NOT_VERIFIED" do
      data = Map.merge(get_legal_entity_data(), %{
        "short_name" => "Nebo15",
        "email" => "changed@example.com",
        "kveds" => ["12.21"]
      })

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(data)

      # test legal entity data
      assert "Nebo15" == legal_entity.short_name
      assert "ACTIVE" == legal_entity.status
      assert "NOT_VERIFIED" == legal_entity.mis_verified
      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified
      assert_security(security, legal_entity.id)

      # test employee request
      assert 1 == Repo.one(from e in EmployeeRequest, select: count("*"))
      assert %EmployeeRequest{data: employee_request_data, status: "NEW"} = Repo.one(from e in EmployeeRequest)
      assert legal_entity.id == employee_request_data["legal_entity_id"]
      assert "лікар" == employee_request_data["position"]
      assert "OWNER" == employee_request_data["employee_type"]

      assert 1 == PRMRepo.one(from l in LegalEntity, select: count("*"))
    end

    test "mis_verified VERIFIED" do
      data = Map.merge(get_legal_entity_data(), %{
        "short_name" => "Nebo15",
        "email" => "changed@example.com",
        "kveds" => ["12.21"]
      })

      insert(:prm, :registry, edrpou: "37367387", type: LegalEntity.type(:msp))

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(data)

      # test legal entity data
      assert "Nebo15" == legal_entity.short_name
      assert "ACTIVE" == legal_entity.status
      assert "VERIFIED" == legal_entity.mis_verified
      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified
      assert_security(security, legal_entity.id)

      # test employee request
      assert 1 == Repo.one(from e in EmployeeRequest, select: count("*"))
      assert %EmployeeRequest{data: employee_request_data, status: "NEW"} = Repo.one(from e in EmployeeRequest)
      assert legal_entity.id == employee_request_data["legal_entity_id"]
      assert "лікар" == employee_request_data["position"]
      assert "OWNER" == employee_request_data["employee_type"]

      assert 1 == PRMRepo.one(from l in LegalEntity, select: count("*"))
    end
  end

  describe "update Legal Entity" do

    test "happy path" do
      insert(:prm, :registry)
      insert(:prm, :legal_entity, edrpou: "10002000")
      insert(:prm, :legal_entity, edrpou: "37367387")

      update_data = Map.merge(get_legal_entity_data(), %{
        "edrpou" => "37367387",
        "short_name" => "Nebo15",
        "email" => "changed@example.com",
        "kveds" => ["12.21"]
      })

      assert {:ok, %{legal_entity: legal_entity, security: security}} = create_legal_entity(update_data)

      assert "37367387" == legal_entity.edrpou
      assert "ACTIVE" == legal_entity.status
      assert "VERIFIED" == legal_entity.mis_verified
      assert "changed@example.com" == legal_entity.email
      assert "Nebo15" == legal_entity.short_name

      refute is_nil(legal_entity.nhs_verified)
      refute legal_entity.nhs_verified

      assert_security(security, legal_entity.id)
      assert %LegalEntity{} = PRMRepo.get(LegalEntity, legal_entity.id)
      assert 2 == PRMRepo.one(from l in LegalEntity, select: count("*"))
    end

    test "update inactive Legal Entity" do
      insert(:prm, :legal_entity, [edrpou: "37367387", is_active: false])

      data = Map.merge(get_legal_entity_data(), %{"edrpou" => "37367387"})

      assert {:ok, %{legal_entity: legal_entity}} = create_legal_entity(data)
      assert true = legal_entity.is_active
    end

    test "invalid status" do
      insert(:prm, :legal_entity, [edrpou: "37367387", status: "CLOSED"])
      assert {:error, {:conflict, "LegalEntity can't be updated"}} == create_legal_entity(get_legal_entity_data())
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

    assert {:error, [{%{description: "invalid settlement value", params: [], rule: :invalid},
      "$.addresses.settlement"}]} == Validator.validate_addresses(content)
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

    assert {:error, [{%{description: "invalid settlement value", params: [], rule: :invalid},
      "$.addresses.settlement"}]} == Validator.validate_addresses(content)
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

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid},
      "$.addresses.region"}]} == Validator.validate_addresses(content)
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

    assert {:error, [{%{description: "invalid region value", params: [], rule: :invalid},
      "$.addresses.region"}]} == Validator.validate_addresses(content)
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

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid},
      "$.addresses.area"}]} == Validator.validate_addresses(content)
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

    assert {:error, [{%{description: "invalid area value", params: [], rule: :invalid},
      "$.addresses.area"}]} == Validator.validate_addresses(content)
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
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end

  defp create_legal_entity(request_params) do
    request = %{
      "signed_legal_entity_request" => Base.encode64(Poison.encode!(request_params)),
      "signed_content_encoding" => "base64",
    }
    API.create_legal_entity(request, get_headers())
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Poison.decode!()
  end
end
