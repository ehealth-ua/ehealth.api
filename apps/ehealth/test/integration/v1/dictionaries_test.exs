defmodule EHealth.Integration.DictionariesTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Core.Expectations.Signature

  alias Core.Dictionaries
  alias Core.EmployeeRequests
  alias Core.LegalEntities, as: API
  alias Core.Validators.KVEDs

  @document_type_dict %{
    "PASSPORT" => "Паспорт",
    "NATIONAL_ID" => "Біометричний паспорт",
    "BIRTH_CERTIFICATE" => "Свідоцтво про народження",
    "TEMPORARY_CERTIFICATE" => "Посвідка на проживання"
  }

  @phone_type_dict %{
    "MOBILE" => "мобільний",
    "LAND_LINE" => "стаціонарний"
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

  @phone_type %{
    "name" => "PHONE_TYPE",
    "values" => %{
      "MOBILE" => "mobile",
      "LANDLINE" => "landline"
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

  describe "Dictionaries boundary allow access to dictionaries" do
    setup _context do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)

      :ok
    end

    test "get_dictionaries/1 can to get 1 dictionary by name" do
      dict = Dictionaries.get_dictionaries(["DOCUMENT_TYPE"])

      assert %{"DOCUMENT_TYPE" => @document_type_dict} == dict
    end

    test "get_dictionaries/1 can to get multiple dictionaries by name" do
      dicts = Dictionaries.get_dictionaries(["DOCUMENT_TYPE", "PHONE_TYPE"])

      assert %{"DOCUMENT_TYPE" => @document_type_dict, "PHONE_TYPE" => @phone_type_dict} == dicts
    end

    test "get_dictionaries_keys/1 can get keys from dictionary" do
      keys = Dictionaries.get_dictionaries_keys(["PHONE_TYPE"])

      assert %{"PHONE_TYPE" => ["LAND_LINE", "MOBILE"]} == keys
    end

    test "get_dictionaries_keys/1 can get keys from multiple dictionaries" do
      keys = Dictionaries.get_dictionaries_keys(["DOCUMENT_TYPE", "PHONE_TYPE"])

      assert %{"DOCUMENT_TYPE" => Map.keys(@document_type_dict), "PHONE_TYPE" => Map.keys(@phone_type_dict)} == keys
    end
  end

  describe "success with Legal Entities" do
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
          "short_name" => "edenlab",
          "email" => "changed@example.com",
          "kveds" => ["12.21"]
        })

      request = %{"data" => %{"content" => content}}
      edrpou_signed_content(content, ["37367387"])

      assert {:error, %Ecto.Changeset{valid?: false}} =
               API.create(
                 %{
                   "signed_content_encoding" => "base64",
                   "signed_legal_entity_request" => Jason.encode!(request)
                 },
                 []
               )
    end
  end

  describe "success with Employee Requests" do
    test "Employee Request: science_degree invalid", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
      patch(conn, dictionary_path(conn, :update, "SCIENCE_DEGREE"), @science_degree)
      patch(conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type)

      content = put_in(get_employee_request(), ~W(employee_request doctor science_degree degree), "INVALID")

      assert {:error, [{%{rule: :inclusion}, "$.employee_request.doctor.science_degree.degree"}]} =
               EmployeeRequests.create(content, [
                 {"x-consumer-metadata", Jason.encode!(%{"client_id" => legal_entity.id})}
               ])
    end

    test "Employee Request: employee_type invalid", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b", legal_entity: legal_entity)
      patch(conn, dictionary_path(conn, :update, "EMPLOYEE_TYPE"), @employee_type)
      patch(conn, dictionary_path(conn, :update, "PHONE_TYPE"), @phone_type)

      content = put_in(get_employee_request(), ~W(employee_request employee_type), "INVALID")

      assert {:error, [{%{rule: :inclusion}, "$.employee_request.employee_type"}]} =
               EmployeeRequests.create(content, [
                 {"x-consumer-metadata", Jason.encode!(%{"client_id" => legal_entity.id})}
               ])
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
  end

  defp get_legal_entity_data do
    "../core/test/data/legal_entity.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp get_employee_request do
    "../core/test/data/employee_doctor_request.json"
    |> File.read!()
    |> Jason.decode!()
    |> put_in(~W(employee_request legal_entity_id), "8b797c23-ba47-45f2-bc0f-521013e01074")
  end
end
