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

  describe "validate authentication_method" do
    test "phone_number is required for OTP type" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "authentication_methods" => [
              %{"type" => "OFFLINE"},
              %{"type" => "OTP"},
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_authentication_methods()

      [
        "data.person.authentication_methods.[1].phone_number": {
          "required property phone_number was not present", []
        }
      ] = result.errors
    end

    test "phone_number is NOT required for OFFLINE type" do
      data =
        "test/data/declaration_request.json"
        |> File.read!()
        |> Poison.decode!()
        |> Map.fetch!("declaration_request")
        |> put_in(~W(person authentication_methods), [%{"type" => "OFFLINE"}])

      assert :ok == validate_schema(data)
    end
  end

  describe "validate_tax_id/1" do
    test "when tax_id is absent" do
      raw_declaration_request = %{
        data: %{
          "person" => %{}
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_tax_id()

      assert [] = result.errors
    end

    test "when tax_id is valid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "tax_id" => "1111111118"
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_tax_id()

      assert [] = result.errors
    end

    test "when tax_id is not valid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "tax_id" => "3126509816"
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_tax_id()

      assert {"Person's tax ID in not valid.", []} = result.errors[:"data.person.tax_id"]
    end
  end

  describe "validate_confidant_persons_tax_id/1" do
    test "when no confidant person exist" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => []
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_persons_tax_id()

      assert [] = result.errors

      raw_declaration_request = %{
        data: %{
          "person" => %{}
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_persons_tax_id()

      assert [] = result.errors
    end

    test "when confidant person does not have tax_id" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => [%{}]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_persons_tax_id()

      assert [] = result.errors
    end

    test "when tax_id is valid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => [
              %{"tax_id" => "1111111118"},
              %{"tax_id" => "2222222225"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_persons_tax_id()

      assert [] = result.errors
    end

    test "when tax_id is not valid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => [
              %{"first_name" => "Alex", "last_name" => "X", "tax_id" => "0000000000"},
              %{"first_name" => "Alex", "last_name" => "X", "tax_id" => "1111111117"},
              %{"first_name" => "Alex", "last_name" => "Y", "tax_id" => "1111111119"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_persons_tax_id()

      assert [
        "data.person.confidant_person[2].tax_id": {"Person's tax ID in not valid.", []},
        "data.person.confidant_person[1].tax_id": {"Person's tax ID in not valid.", []},
        "data.person.confidant_person[0].tax_id": {"Person's tax ID in not valid.", []}
      ] = result.errors
    end
  end

  describe "validate_addresses/1" do
    test "when addresses are valid" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "addresses" => [
              %{"type" => "REGISTRATION"},
              %{"type" => "RESIDENCE"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_person_addresses()

      assert [] = result.errors
    end

    test "when there are more than one REGISTRATION address" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "addresses" => [
              %{"type" => "REGISTRATION"},
              %{"type" => "REGISTRATION"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_person_addresses()

      assert ["data.person.addresses": {"one and only one registration address is required", []}] = result.errors
    end

    test "when there no REGISTRATION address" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "addresses" => []
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_person_addresses()

      assert ["data.person.addresses": {"one and only one registration address is required", []}] = result.errors
    end

    test "when there are more than one RESIDENCE address" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "addresses" => [
              %{"type" => "REGISTRATION"},
              %{"type" => "RESIDENCE"},
              %{"type" => "RESIDENCE"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_person_addresses()

      assert ["data.person.addresses": {"one and only one residence address is required", []}] = result.errors
    end

    test "when there no RESIDENCE address" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "addresses" => [
              %{"type" => "REGISTRATION"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_person_addresses()

      assert ["data.person.addresses": {"one and only one residence address is required", []}] = result.errors
    end
  end

  describe "validate_confidant_person_rel_type/1" do
    test "when no confidant person exist" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => []
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_person_rel_type()

      assert [] = result.errors

      raw_declaration_request = %{
        data: %{
          "person" => %{}
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_person_rel_type()

      assert [] = result.errors
    end

    test "when exactly one confidant person is PRIMARY" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => [
              %{"relation_type" => "PRIMARY"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_person_rel_type()

      assert [] = result.errors
    end

    test "when more than one confidant person is PRIMARY" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "confidant_person" => [
              %{"relation_type" => "PRIMARY"},
              %{"relation_type" => "PRIMARY"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> validate_confidant_person_rel_type()

      assert [
        "data.person.confidant_persons[].relation_type": {
          "one and only one confidant person with type PRIMARY is required", []
        }
      ] = result.errors
    end
  end
end
