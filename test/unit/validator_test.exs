defmodule EHealth.Unit.ValidatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias EHealth.LegalEntity.Validator
  alias EHealth.LegalEntity.ValidatorKVEDs
  alias EHealth.API.MediaStorage
  alias EHealth.Employee.API, as: EmployeeRequestAPI

  @phone_type %{
    "name" => "PHONE_TYPE",
    "values" => %{
      "MOBILE" => "mobile",
      "LANDLINE" => "landline",
    },
    "labels" => ["SYSTEM"],
    "is_active" => true,
  }

  @legal_entity_type %{
    "name" => "LEGAL_ENTITY_TYPE",
    "values" => %{
      "MSP" => "MSP",
      "MIS" => "MIS",
    },
    "labels" => ["SYSTEM"],
    "is_active" => true,
  }

  @kveds %{
    "name" => "KVEDS",
    "values" => %{
      "21.20": "Виробництво фармацевтичних препаратів і матеріалів",
      "38.31": "Демонтаж (розбирання) машин і устатковання",
      "56.21": "Постачання готових страв для подій",
      "82.11": "Надання комбінованих офісних адміністративних послуг",
    },
    "labels" => ["SYSTEM", "EXTERNAL"],
    "is_active" => true,
  }

  @unmapped %{
    "name" => "UNMAPPED",
    "values" => %{
      "NEW" => "yes",
    },
    "labels" => ["SYSTEM"],
    "is_active" => true,
  }

  test "JSON schema dictionary enum validate LEGAL_ENTITY_TYPE", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "LEGAL_ENTITY_TYPE"), @legal_entity_type

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> Map.put("type", "STRANGE")

    assert {:error, [{%{description: "value is not allowed in enum", rule: :inclusion}, "$.type"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema dictionary enum validate PHONE_TYPE", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> Map.put("phones", [%{"type" => "INVALID", "number" => "+380503410870"}])

    assert {:error, [{%{description: "value is not allowed in enum", rule: :inclusion}, "$.phones.[0].type"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema birth_date date format with weeks" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["owner", "birth_date"], "1985-W12-6")

    assert {:error, [{%{description: _, rule: :format}, "$.owner.birth_date"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema birth_date date format" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["owner", "birth_date"], "1988.12.11")

    assert {:error, [{%{description: _, rule: :format}, "$.owner.birth_date"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema issued_date date format" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["medical_service_provider", "accreditation", "issued_date"], "20-12-2011")

    assert {:error, [{%{description: _, rule: :format}, "$.medical_service_provider.accreditation.issued_date"}]} =
      Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "JSON schema employee request issued_date date format" do
    content =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["employee_request", "legal_entity_id"], "8b797c23-ba47-45f2-bc0f-521013e01074")
      |> put_in(["employee_request", "doctor", "science_degree", "issued_date"], "20.12.2011")

    assert {:error, [{%{description: _, rule: :format}, "$.employee_request.doctor.science_degree.issued_date"}]} =
      EmployeeRequestAPI.create_employee_request(content)
  end

  test "JSON schema employee request start_date date format" do
    content =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["employee_request", "legal_entity_id"], "8b797c23-ba47-45f2-bc0f-521013e01074")
      |> put_in(["employee_request", "start_date"], "2012-12")

    assert {:error, [{%{description: _, rule: :format}, "$.employee_request.start_date"}]} =
      EmployeeRequestAPI.create_employee_request(content)
  end

  test "JSON schema employee request educations issued_date format" do
    content =
      "test/data/employee_request.json"
      |> File.read!()
      |> Poison.decode!()
      |> put_in(["employee_request", "legal_entity_id"], "8b797c23-ba47-45f2-bc0f-521013e01074")

    education =
      content
      |> get_in(["employee_request", "doctor", "educations"])
      |> List.first()

    content = put_in(content,
      ["employee_request", "doctor", "educations"],
      [Map.put(education, "issued_date", "2012")])

    assert {:error, [{%{description: _, rule: :format}, "$.employee_request.doctor.educations.[0].issued_date"}]} =
      EmployeeRequestAPI.create_employee_request(content)
  end

  test "unmapped dictionary name", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "UNMAPPED"), @unmapped

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Poison.decode!()

    assert {:ok, _} = Validator.validate_legal_entity({:ok, %{"data" => %{"content" => content}}})
  end

  test "base64 decode signed_content with white spaces" do
    signed_content = File.read!("test/data/signed_content_whitespace.txt")
    data = {:ok, %{"data" => %{"secret_url" => "http://localhost:4040/signed_url_test"}}}

    assert {:ok, "http://example.com?signed_url=true"} == MediaStorage.put_signed_content(data, signed_content)
  end

  test "validate allowed kveds", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "KVEDS"), @kveds
    assert %Ecto.Changeset{valid?: true} = ValidatorKVEDs.validate(["82.11"])
  end

  test "validate not allowed kveds", %{conn: conn} do
    patch conn, dictionary_path(conn, :update, "KVEDS"), @kveds
    assert %Ecto.Changeset{valid?: false} = ValidatorKVEDs.validate(["12.11"])
  end

  test "validate kveds with empty dictionary" do
    assert %Ecto.Changeset{valid?: true} = ValidatorKVEDs.validate(["12.11"])
  end
end
