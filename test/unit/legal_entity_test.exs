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

    Validator.decode_and_validate(%{
      "signed_content_encoding" => "base64",
      "signed_legal_entity_request" => content
    })
  end

  test "invalid signed content validation" do
    Validator.decode_and_validate(%{
      "signed_content_encoding" => "base256",
      "signed_legal_entity_request" => "invalid"
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

    assert {:ok, content} == validate_edrpou(content, signer)
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
    legal_entitity = Map.merge(get_legal_entity_data(), %{"edrpou" => "07367380"})

    assert {:ok, resp, secret} = API.process_request({:ok, legal_entitity}, get_headers())
    assert "NOT_VERIFIED" == resp["status"]
    assert secret
    assert 1 == Repo.one(from e in EmployeeRequest, select: count("*"))
  end

  test "process legal entity that exists" do
    legal_entitity = Map.merge(get_legal_entity_data(), %{
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })

    assert {:ok, resp, security} = API.process_request({:ok, legal_entitity}, get_headers())
    assert "37367387" == resp["edrpou"]
    assert "VERIFIED" == resp["status"]
    assert Map.has_key?(security, "client_id")
    assert Map.has_key?(security, "client_secret")
    assert Map.has_key?(security, "redirect_uri")
    # security
    assert resp["id"] == security["client_id"]
    refute nil == security["client_secret"]
    refute nil == security["redirect_uri"]
  end

  test "update legal entity" do
    legal_entitity = Map.merge(get_legal_entity_data(), %{
      "short_name" => "Nebo15",
      "email" => "changed@example.com",
      "kveds" => ["12.21"]
    })

    get_legal_entity_resp = {:ok, %{
      "data" => [
        %{"id" => "7cc91a5d-c02f-41e9-b571-1ea4f2375552"}
      ]
    }}

    assert {:ok, %{"data" => resp}, %{"client_id" => _, "client_secret" => _, "redirect_uri" => _}} =
      API.create_or_update(get_legal_entity_resp, legal_entitity, get_headers())
    assert "Nebo15" == resp["short_name"]
    assert "37367387" == resp["edrpou"]
    assert "VERIFIED" == resp["status"]
    assert "changed@example.com" == resp["email"]
    assert ["86.01"] == resp["kveds"]
  end

  test "create client with legal_entity id" do
    id = UUID.generate()
    legal_entity = {:ok, %{"data" => %{"id" => id, "short_name" => "test"}}}
    assert {:ok, %{"data" => %{"id" => ^id}}, _} = OAuth.create_client(legal_entity, "http://example.com", [])
  end

  # helpers

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
