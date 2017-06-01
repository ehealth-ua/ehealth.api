defmodule EHealth.Unit.LegalEntityTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Ecto.Query, warn: false

  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.LegalEntity.API
  alias EHealth.LegalEntity.Validator

  test "successed signed content validation" do
    content = File.read!("test/data/signed_content.txt")

    assert {:ok, _} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "invalid signed content validation" do
    assert %Ecto.Changeset{valid?: false} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base256",
      "signed_legal_entity_request" => "invalid"
    })
  end

  test "invalid signed content - no security" do
    content = File.read!("test/data/signed_content_no_security.txt")

    assert {:error, _} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "invalid signed content - birth date format" do
    content = File.read!("test/data/signed_content_invalid_owner_birth_date.txt")

    assert {:error, _} = Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "validate decoded legal entity" do
    content = get_legal_entity_data()

    data = %{"data" => %{"content" => content}}

    assert {:ok, %{"content" => content}} == Validator.validate_legal_entity({:ok, data})
  end

  test "validate legal entity EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "37367387"}

    assert {:ok, %{legal_entity_request: content}} == validate_edrpou(content, signer)
  end

  test "empty signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"empty" => "37367387"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "invalid signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "03736738a"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "employee request start_date format" do
    %{"employee_request" => data} = API.prepare_employee_request_data(UUID.generate(), %{"position" => "лікар"})
    assert Map.has_key?(data, "start_date")
    assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, data["start_date"])
  end

  test "different signer EDRPOU" do
    content = get_legal_entity_data()

    signer = %{"edrpou" => "0373167387"}

    assert %Ecto.Changeset{valid?: false} = validate_edrpou(content, signer)
  end

  test "new legal entity status NOT_VERIFIED" do
    assert {:ok, %{legal_entity_prm: %{"data" => legal_entity}, security: security}} =
      API.create_legal_entity(%{
        "signed_legal_entity_request" => File.read!("test/data/signed_content.txt"),
        "signed_content_encoding" => "base64"},
        get_headers()
      )

    assert "NOT_VERIFIED" == legal_entity["status"]
    assert_security(security, legal_entity["id"])
    assert 1 == Repo.one(from e in EmployeeRequest, select: count("*"))
  end

  test "process legal entity that exists" do
    legal_entity = Map.merge(get_legal_entity_data(), %{
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })
    request = %{
      "signed_legal_entity_request" => "base64 encoded content"
    }

    assert {:ok, %{legal_entity_prm: %{"data" => legal_entity}, security: security}} =
      API.process_request({:ok, %{legal_entity_request: legal_entity}}, request, get_headers())

    assert "37367387" == legal_entity["edrpou"]
    assert "VERIFIED" == legal_entity["status"]
    assert_security(security, legal_entity["id"])
  end

  test "update legal entity" do
    legal_entity = Map.merge(get_legal_entity_data(), %{
      "edrpou" => "12345678",
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })

    data = %{
      legal_entity_id: UUID.generate(),
      legal_entity_flow: :update,
      legal_entity_request: legal_entity
    }

    assert {:ok, %{legal_entity_prm: %{"data" => legal_entity}}} =
      API.put_legal_entity_to_prm({:ok, data}, get_headers())

    assert "Nebo15" == legal_entity["short_name"]
    assert "37367387" == legal_entity["edrpou"]
    assert "VERIFIED" == legal_entity["status"]
    assert "changed@example.com" == legal_entity["email"]
    assert ["86.01"] == legal_entity["kveds"]
  end

  test "update inactive legal entity" do
    legal_entity = Map.merge(get_legal_entity_data(), %{
      "edrpou" => "10002000"
    })
    request = %{
      "signed_legal_entity_request" => "base64 encoded content"
    }
    assert {:ok, %{legal_entity_prm: %{"data" => %{"is_active" => true}}, security: _security}} =
          API.process_request({:ok, %{legal_entity_request: legal_entity}}, request, get_headers())
  end

  test "create client with legal_entity id" do
    id = UUID.generate()
    legal_entity = %{"id" => id, "name" => "test"}
    assert {:ok, %{"data" => %{"id" => ^id}}} = OAuth.create_client(legal_entity, "http://example.com", [])
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

  defp validate_edrpou(content, signer) do
    Validator.validate_edrpou({:ok, %{
      "content" => content,
      "signer" => signer
    }})
  end

  defp get_legal_entity_data do
    "test/data/legal_entity.json"
    |> File.read!()
    |> Poison.decode!()
  end
end
