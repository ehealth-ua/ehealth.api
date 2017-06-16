defmodule EHealth.DeclarationRequest.API.ValidationTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Validations
  alias EHealth.DeclarationRequest

  describe "validate_patient_age/3" do
    test "patient's age matches doctor's speciality" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "birth_date" => "2000-01-19"
          },
          "employee_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_patient_age(["PEDIATRICIAN"], 18)

      assert is_nil(result.errors[:data])
    end

    test "patient's age does not match doctor's speciality" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "birth_date" => "1990-01-19"
          },
          "employee_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_patient_age(["PEDIATRICIAN"], 18)

      assert result.errors[:data] == {"Doctor speciality does not meet the patient's age requirement.", []}
    end
  end

  describe "validate_patient_phone_number/1" do
    test "validation is successful" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "phones" => [
              %{ "type" => "MOBILE", "number" => "+380508887700" },
              %{ "type" => "MOBILE", "number" => "+380991234567" }
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_patient_phone_number()

      assert is_nil(result.errors[:data])
    end

    test "validation is not successful" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "phones" => [
              %{ "type" => "MOBILE", "number" => "+380509999888" },
              %{ "type" => "MOBILE", "number" => "+380509999777" }
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_patient_phone_number()

      assert result.errors[:data] == {"The phone number is not verified.", []}
    end
  end

  describe "belongs_to/3" do
    test "checks if doctor falls into given adult age" do
      assert belongs_to(17, 18, "PEDIATRICIAN")
      refute belongs_to(18, 18, "PEDIATRICIAN")
      refute belongs_to(19, 18, "PEDIATRICIAN")

      refute belongs_to(17, 18, "THERAPIST")
      assert belongs_to(18, 18, "THERAPIST")
      assert belongs_to(19, 18, "THERAPIST")

      assert belongs_to(17, 18, "FAMILY_DOCTOR")
      assert belongs_to(18, 18, "FAMILY_DOCTOR")
      assert belongs_to(19, 18, "FAMILY_DOCTOR")
    end
  end
end
