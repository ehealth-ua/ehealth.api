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

    test "patient's age invalid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "birth_date" => "1812-01-19"
          },
          "employee_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_patient_birth_date()

      assert result.errors[:data] == {"Invalid birth date.", []}
    end
  end

  describe "validate_patient_phone_number/1" do
    defmodule SuccessfulPhoneVerification do
      use MicroservicesHelper

      Plug.Router.get "/verifications/+380991234567" do
        send_resp(conn, 200, Poison.encode!(%{data: ["response_we_don't_care_about"]}))
      end

      Plug.Router.get "/verifications/+380508887700" do
        send_resp(conn, 404, Poison.encode!(%{}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(SuccessfulPhoneVerification)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

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
              %{ "type" => "MOBILE", "number" => "+380508887700" }
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

  test "validate_schema/1" do
    assert {:error, _} = validate_schema(%{})
  end
end
