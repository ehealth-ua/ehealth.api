defmodule Core.Unit.ValidatorTest do
  @moduledoc false

  use Core.ConnCase
  import Mox

  alias Core.API.MediaStorage
  alias Core.EmployeeRequests
  alias Core.LegalEntities.Validator
  alias Core.Validators.KVEDs
  alias Ecto.UUID

  setup :verify_on_exit!

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
      :second
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
             EmployeeRequests.create(content, [
               {"x-consumer-metadata", Jason.encode!(%{"client_id" => legal_entity.id})}
             ])
  end

  test "Employee Request: start_date date format" do
    legal_entity = insert(:prm, :legal_entity)
    insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
    content = put_in(get_employee_request(), ["employee_request", "start_date"], "2012-12")

    assert {:error, [{%{description: _, rule: :date}, "$.employee_request.start_date"}]} =
             EmployeeRequests.create(content, [
               {"x-consumer-metadata", Jason.encode!(%{"client_id" => legal_entity.id})}
             ])
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
             EmployeeRequests.create(content, [
               {"x-consumer-metadata", Jason.encode!(%{"client_id" => legal_entity.id})}
             ])
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
