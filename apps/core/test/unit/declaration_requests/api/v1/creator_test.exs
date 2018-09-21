defmodule Core.DeclarationRequests.API.V1.CreatorTest do
  @moduledoc false

  use Core.ConnCase, async: true

  import Mox

  alias Ecto.UUID
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.DeclarationRequests.API.V1.Creator
  alias Core.Repo
  alias Core.Utils.NumberGenerator

  describe "gen_sequence_number" do
    test "nuber generated successfully" do
      expect(DeclarationRequestsCreatorMock, :sql_get_sequence_number, fn ->
        {:ok, %Postgrex.Result{rows: [[Enum.random(1_000_000..2_000_000)]]}}
      end)

      assert {:ok, _} = Creator.get_sequence_number()
    end

    test "nuber generated fail" do
      expect(DeclarationRequestsCreatorMock, :sql_get_sequence_number, fn ->
        {:error, [:any]}
      end)

      assert {:error, %{"type" => "internal_error"}} = Creator.get_sequence_number()
    end
  end

  describe "request_end_date/5" do
    test "patient is less than 18 years old, speciality: PEDIATRICIAN" do
      term = [years: 40]
      birth_date = "2014-10-10"
      today = Date.from_iso8601!("2017-10-16")

      assert ~D[2032-10-09] == Creator.request_end_date("PEDIATRICIAN", today, term, birth_date, 18)
    end

    test "patient is less than 18 years old, speciality: FAMILY_DOCTOR" do
      term = [years: 40]
      birth_date = "2014-10-10"
      today = Date.from_iso8601!("2017-10-16")

      assert ~D[2057-10-16] == Creator.request_end_date("FAMILY_DOCTOR", today, term, birth_date, 18)
    end

    test "patient turns 18 years old tomorrow" do
      term = [years: 40]
      birth_date = "2000-10-17"
      today = Date.from_iso8601!("2018-10-16")

      assert ~D[2018-10-16] == Creator.request_end_date("PEDIATRICIAN", today, term, birth_date, 18)
    end

    test "patient turns 18 years today" do
      term = [years: 40]
      birth_date = "2000-10-17"
      today = Date.from_iso8601!("2018-10-17")

      assert ~D[2058-10-17] == Creator.request_end_date("FAMILY_DOCTOR", today, term, birth_date, 18)
    end

    test "patient is older than 18 years" do
      term = [years: 40]
      birth_date = "1988-10-10"
      today = Date.from_iso8601!("2017-10-16")

      assert ~D[2057-10-16] == Creator.request_end_date("THERAPIST", today, term, birth_date, 18)
    end

    test "take min between 18 years and declaration term date, speciality: PEDIATRICIAN" do
      term = [years: 5]
      birth_date = "1988-10-10"
      today = Date.from_iso8601!("1990-10-10")

      assert ~D[1995-10-10] == Creator.request_end_date("PEDIATRICIAN", today, term, birth_date, 18)
    end
  end

  test "patient is underage, speciality: FAMILY_DOCTOR" do
    term = [years: 40]
    birth_date = "2010-10-10"
    today = Date.from_iso8601!("2017-10-16")

    assert ~D[2057-10-16] == Creator.request_end_date("THERAPIST", today, term, birth_date, 18)
  end

  describe "validate_patient_age/3" do
    test "patient's age matches doctor's speciality" do
      year = DateTime.utc_now() |> Map.fetch!(:year) |> Kernel.-(17)

      raw_declaration_request = %{
        data: %{
          "person" => %{
            "birth_date" => "#{year}-01-01"
          },
          "employee_id" => "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b"
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> Creator.validate_patient_age("PEDIATRICIAN", 18)

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
        |> Creator.validate_patient_age("PEDIATRICIAN", 18)

      assert result.errors[:data] == {"Doctor speciality doesn't match patient's age", [validation: "invalid_age"]}
    end
  end

  describe "validate_patient_birth_date/1" do
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
        |> Creator.validate_patient_birth_date()

      assert result.errors[:data] == {"Invalid birth date.", []}
    end
  end

  describe "belongs_to/3" do
    test "checks if doctor falls into given adult age" do
      assert Creator.belongs_to(17, 18, "PEDIATRICIAN")
      refute Creator.belongs_to(18, 18, "PEDIATRICIAN")
      refute Creator.belongs_to(19, 18, "PEDIATRICIAN")

      refute Creator.belongs_to(17, 18, "THERAPIST")
      assert Creator.belongs_to(18, 18, "THERAPIST")
      assert Creator.belongs_to(19, 18, "THERAPIST")

      assert Creator.belongs_to(17, 18, "FAMILY_DOCTOR")
      assert Creator.belongs_to(18, 18, "FAMILY_DOCTOR")
      assert Creator.belongs_to(19, 18, "FAMILY_DOCTOR")
    end
  end

  describe "validate authentication_method" do
    test "phone_number is required for OTP type" do
      raw_declaration_request = %{
        data: %{
          "person" => %{
            "authentication_methods" => [
              %{"type" => "OFFLINE"},
              %{"type" => "OTP"}
            ]
          }
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> Creator.validate_authentication_methods()

      [
        "data.person.authentication_methods.[1].phone_number": {
          "required property phone_number was not present",
          []
        }
      ] = result.errors
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
        |> Creator.validate_tax_id()

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
        |> Creator.validate_tax_id()

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
        |> Creator.validate_tax_id()

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
        |> Creator.validate_confidant_persons_tax_id()

      assert [] = result.errors

      raw_declaration_request = %{
        data: %{
          "person" => %{}
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> Creator.validate_confidant_persons_tax_id()

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
        |> Creator.validate_confidant_persons_tax_id()

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
        |> Creator.validate_confidant_persons_tax_id()

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
        |> Creator.validate_confidant_persons_tax_id()

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
        |> Creator.validate_person_addresses()

      assert [] = result.errors
    end

    test "when there are more than one REGISTRATION address and no RESIDENCE" do
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
        |> Creator.validate_person_addresses()

      assert ["data.person.addresses": {"one and only one residence address is required", []}] = result.errors
    end

    test "when there no REGISTRATION address, RESIDENCE required" do
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
        |> Creator.validate_person_addresses()

      assert ["data.person.addresses": {"one and only one residence address is required", []}] = result.errors
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
        |> Creator.validate_person_addresses()

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
        |> Creator.validate_person_addresses()

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
        |> Creator.validate_confidant_person_rel_type()

      assert [] = result.errors

      raw_declaration_request = %{
        data: %{
          "person" => %{}
        }
      }

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change(raw_declaration_request)
        |> Creator.validate_confidant_person_rel_type()

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
        |> Creator.validate_confidant_person_rel_type()

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
        |> Creator.validate_confidant_person_rel_type()

      assert [
               "data.person.confidant_persons[].relation_type": {
                 "one and only one confidant person with type PRIMARY is required",
                 []
               }
             ] = result.errors
    end
  end

  describe "validate_employee_type/2" do
    test "when employee is doctor" do
      employee = %{employee_type: "DOCTOR"}

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change()
        |> Creator.validate_employee_type(employee)

      assert [] = result.errors
    end

    test "when employee is not doctor" do
      employee = %{employee_type: "OWNER"}

      result =
        %DeclarationRequest{}
        |> Ecto.Changeset.change()
        |> Creator.validate_employee_type(employee)

      assert [
               "data.person.employee_id": {
                 "Employee ID must reference a doctor.",
                 []
               }
             ] = result.errors
    end
  end

  describe "pending_declaration_requests/2" do
    test "returns pending requests" do
      existing_declaration_request_data = %{
        "person" => %{
          "tax_id" => "111"
        },
        "employee" => %{
          "id" => "222"
        },
        "legal_entity" => %{
          "id" => "333"
        }
      }

      {:ok, pending_declaration_req_1} = copy_declaration_request(existing_declaration_request_data, "NEW")
      {:ok, pending_declaration_req_2} = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query = Creator.pending_declaration_requests(%{"tax_id" => "111"}, "222", "333")
      requests = Repo.all(query)
      assert pending_declaration_req_1 in requests
      assert pending_declaration_req_2 in requests
    end

    test "returns pending requests without tax_id" do
      existing_declaration_request_data = %{
        "person" => %{
          "first_name" => "Василь",
          "last_name" => "Шамрило",
          "birth_data" => "2000-12-14"
        },
        "employee" => %{
          "id" => "222"
        },
        "legal_entity" => %{
          "id" => "333"
        }
      }

      {:ok, pending_declaration_req_1} = copy_declaration_request(existing_declaration_request_data, "NEW")
      {:ok, pending_declaration_req_2} = copy_declaration_request(existing_declaration_request_data, "APPROVED")

      query = Creator.pending_declaration_requests(%{}, "222", "333")
      declarations = Repo.all(query)
      assert pending_declaration_req_1 in declarations
      assert pending_declaration_req_2 in declarations
    end
  end

  describe "mpi persons search" do
    test "few mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => [%{id: 1}, %{id: 2}]
         }}
      end)

      assert {:ok, nil} =
               Creator.mpi_search(%{"unzr" => "20160828-12345", "birth_date" => "2016-08-28", "tax_id" => "0123456789"})
    end

    test "one mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => [%{id: 1}]
         }}
      end)

      assert {:ok, %{id: 1}} =
               Creator.mpi_search(%{"unzr" => "20160303-12345", "birth_date" => "2016-03-03", "tax_id" => "0123456789"})
    end

    test "no mpi persons" do
      expect(MPIMock, :search, fn _, _ ->
        {:ok,
         %{
           "data" => []
         }}
      end)

      assert {:ok, nil} =
               Creator.mpi_search(%{"unzr" => "20190101-12345", "birth_date" => "2019-01-01", "tax_id" => "1234567890"})
    end
  end

  defp copy_declaration_request(template, status) do
    attrs = %{
      "status" => status,
      "data" => %{
        "person" => %{
          "tax_id" => get_in(template, ["person", "tax_id"])
        },
        "employee" => %{
          "id" => get_in(template, ["employee", "id"])
        },
        "legal_entity" => %{
          "id" => get_in(template, ["legal_entity", "id"])
        }
      },
      "authentication_method_current" => %{
        "number" => "+380508887700",
        "type" => "OTP"
      },
      "documents" => [],
      "printout_content" => "Some fake content",
      "inserted_by" => UUID.generate(),
      "updated_by" => UUID.generate(),
      "declaration_id" => UUID.generate(),
      "channel" => DeclarationRequest.channel(:mis),
      "declaration_number" => NumberGenerator.generate(1, 2)
    }

    allowed =
      attrs
      |> Map.keys()
      |> Enum.map(&String.to_atom(&1))

    %DeclarationRequest{}
    |> Ecto.Changeset.cast(attrs, allowed)
    |> Repo.insert()
  end
end
