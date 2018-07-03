defmodule EHealth.Unit.ValidatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox

  alias EHealth.LegalEntities.Validator
  alias EHealth.Validators.KVEDs
  alias EHealth.API.MediaStorage
  alias EHealth.EmployeeRequests
  alias Ecto.UUID

  setup :verify_on_exit!

  @phone_type %{
    "name" => "PHONE_TYPE",
    "values" => %{
      "MOBILE" => "mobile",
      "LANDLINE" => "landline"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  @legal_entity_type %{
    "name" => "LEGAL_ENTITY_TYPE",
    "values" => %{
      "MSP" => "MSP",
      "MIS" => "MIS"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  @employee_type %{
    "name" => "EMPLOYEE_TYPE",
    "values" => %{
      "DOCTOR" => "doctor"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  @science_degree %{
    "name" => "SCIENCE_DEGREE",
    "values" => %{
      "Candidate_of_Science" => "Candidate of Science",
      "Doctor_of_Science" => "Doctor of Science",
      "PhD" => "PhD"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  @kveds_allowed %{
    "name" => "KVEDS_ALLOWED",
    "values" => %{
      "21.20": "Виробництво фармацевтичних препаратів і матеріалів"
    },
    "labels" => ["SYSTEM", "EXTERNAL"],
    "is_active" => true
  }

  @kveds %{
    "name" => "KVEDS",
    "values" => %{
      "21.20": "Виробництво фармацевтичних препаратів і матеріалів",
      "38.31": "Демонтаж (розбирання) машин і устатковання",
      "56.21": "Постачання готових страв для подій",
      "82.11": "Надання комбінованих офісних адміністративних послуг"
    },
    "labels" => ["SYSTEM", "EXTERNAL"],
    "is_active" => true
  }

  @unmapped %{
    "name" => "UNMAPPED",
    "values" => %{
      "NEW" => "yes"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  test "JSON schema dictionary enum validate LEGAL_ENTITY_TYPE", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "LEGAL_ENTITY_TYPE"), @legal_entity_type)

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.put("type", "STRANGE")

    assert {:error, [{%{description: "value is not allowed in enum", rule: :inclusion}, "$.type"}]} =
             Validator.validate_schema(content)
  end

  test "JSON schema dictionary enum validate PHONE_TYPE", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type)

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> Map.put("phones", [%{"type" => "INVALID", "number" => "+380503410870"}])

    assert {:error, [{%{description: "value is not allowed in enum", rule: :inclusion}, "$.phones.[0].type"}]} =
             Validator.validate_schema(content)
  end

  test "JSON schema owner position not allowed" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "position"], "P99")

    assert {:error, [{%{description: _, rule: :invalid}, "$.owner.position"}]} =
             Validator.validate_owner_position(content)
  end

  test "JSON schema owner position fetched from system env" do
    System.put_env("OWNER_POSITIONS", "P100, P99")

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "position"], "P99")

    assert :ok = Validator.validate_owner_position(content)
    System.put_env("OWNER_POSITIONS", "P1")
  end

  test "JSON schema birth_date date format with weeks" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "birth_date"], "1985-W12-6")

    assert {:error, [{%{description: _, rule: :format}, "$.owner.birth_date"}]} = Validator.validate_schema(content)
  end

  test "JSON schema birth_date date format" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "birth_date"], "1988.12.11")

    assert {:error, [{%{description: _, rule: :format}, "$.owner.birth_date"}]} = Validator.validate_schema(content)
  end

  test "JSON schema birth_date more than 150 years" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "birth_date"], "1815-12-06")

    assert {:error, [{%{description: _, rule: :invalid}, "$.owner.birth_date"}]} =
             Validator.validate_owner_birth_date(content)
  end

  test "JSON schema birth_date in future" do
    date =
      :seconds
      |> :os.system_time()
      |> Kernel.+(3600 * 24 * 180)
      |> DateTime.from_unix!()
      |> Date.to_iso8601()

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["owner", "birth_date"], date)

    assert {:error, [{%{description: _, rule: :invalid}, "$.owner.birth_date"}]} =
             Validator.validate_owner_birth_date(content)
  end

  test "JSON schema issued_date date format" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()
      |> put_in(["medical_service_provider", "accreditation", "issued_date"], "20-12-2011")

    assert {:error, [{%{description: _, rule: :format}, "$.medical_service_provider.accreditation.issued_date"}]} =
             Validator.validate_schema(content)
  end

  test "Employee Request: issued_date date format" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)

    content =
      put_in(
        get_employee_request(),
        ["employee_request", "doctor", "science_degree", "issued_date"],
        "20.12.2011"
      )

    assert {:error, [{%{description: _, rule: :date}, "$.employee_request.doctor.science_degree.issued_date"}]} =
             EmployeeRequests.create(content, legal_entity.id)
  end

  test "Employee Request: start_date date format" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
    content = put_in(get_employee_request(), ["employee_request", "start_date"], "2012-12")

    assert {:error, [{%{description: _, rule: :date}, "$.employee_request.start_date"}]} =
             EmployeeRequests.create(content, legal_entity.id)
  end

  test "Employee Request: educations issued_date format" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
    content = get_employee_request()

    education =
      content
      |> get_in(["employee_request", "doctor", "educations"])
      |> List.first()

    content = put_in(content, ["employee_request", "doctor", "educations"], [Map.put(education, "issued_date", "2012")])

    assert {:error, [{%{description: _, rule: :date}, "$.employee_request.doctor.educations.[0].issued_date"}]} =
             EmployeeRequests.create(content, legal_entity.id)
  end

  test "Employee Request: science_degree invalid", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
    patch(conn, dictionary_path(conn, :update, "SCIENCE_DEGREE"), @science_degree)
    patch(conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type)

    content = put_in(get_employee_request(), ~W(employee_request doctor science_degree degree), "INVALID")

    assert {:error, [{%{rule: :inclusion}, "$.employee_request.doctor.science_degree.degree"}]} =
             EmployeeRequests.create(content, legal_entity.id)
  end

  test "Employee Request: employee_type invalid", %{conn: conn} do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
    patch(conn, dictionary_path(conn, :update, "EMPLOYEE_TYPE"), @employee_type)
    patch(conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type)

    content = put_in(get_employee_request(), ~W(employee_request employee_type), "INVALID")

    assert {:error, [{%{rule: :inclusion}, "$.employee_request.employee_type"}]} =
             EmployeeRequests.create(content, legal_entity.id)
  end

  test "unmapped dictionary name", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "UNMAPPED"), @unmapped)

    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()

    assert :ok = Validator.validate_schema(content)
  end

  test "base64 decode signed_content with white spaces" do
    signed_content = File.read!("test/data/signed_content_whitespace.txt")

    expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
      {:ok, %{"data" => %{"secret_url" => "http://example.com/signed_url_test"}}}
    end)

    expect(MediaStorageMock, :put_signed_content, fn _, _, _, _ ->
      %HTTPoison.Response{status_code: 201, body: "http://example.com?signed_url=true"}
    end)

    assert {:ok, "http://example.com?signed_url=true"} ==
             MediaStorage.store_signed_content(
               true,
               :test_bucket,
               signed_content,
               UUID.generate(),
               "signed_content",
               []
             )
  end

  test "validate address building" do
    content =
      "test/data/legal_entity.json"
      |> File.read!()
      |> Jason.decode!()

    address =
      content
      |> Map.get("addresses")
      |> List.first()

    content =
      Map.put(content, "addresses", [
        Map.put(address, "building", "12-И"),
        Map.put(address, "building", "109-а/2-В"),
        Map.put(address, "building", "10/999"),
        Map.put(address, "building", "010")
      ])

    assert {:error, [{%{description: _, rule: :format}, "$.addresses.[3].building"}]} =
             Validator.validate_schema(content)
  end

  test "validate allowed and required kveds", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "KVEDS"), @kveds)
    patch(conn, dictionary_path(conn, :update, "KVEDS_ALLOWED"), @kveds_allowed)

    insert(:il, :dictionary, name: "KVEDS_ALLOWED_MSP", values: %{"21.20" => ""})
    assert %Ecto.Changeset{valid?: true} = KVEDs.validate(["21.20"])
    assert %Ecto.Changeset{valid?: true} = KVEDs.validate(["82.11", "21.20"])

    # missed required
    assert %Ecto.Changeset{valid?: false} = KVEDs.validate(["82.11"])
    # not valid
    assert %Ecto.Changeset{valid?: false} = KVEDs.validate(["21.20", "99.11"])
  end

  test "validate allowed kveds", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "KVEDS"), @kveds)
    assert %Ecto.Changeset{valid?: true} = KVEDs.validate(["82.11"])
  end

  test "validate not allowed kveds", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "KVEDS"), @kveds)
    assert %Ecto.Changeset{valid?: false} = KVEDs.validate(["12.11"])
  end

  test "validate kveds with empty dictionary" do
    assert %Ecto.Changeset{valid?: true} = KVEDs.validate(["12.11"])
  end

  defp get_employee_request do
    "test/data/employee_doctor_request.json"
    |> File.read!()
    |> Jason.decode!()
    |> put_in(~W(employee_request legal_entity_id), "8b797c23-ba47-45f2-bc0f-521013e01074")
  end
end
