defmodule EHealth.DeclarationRequest.API.ValidatePersonTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.DeclarationRequest.API.ValidatePerson

  describe "Additional validation of JSON request: ValidatePerson.validate/1" do
    setup _context do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_authentication_method)
      insert(:il, :dictionary_document_relationship_type)

      person = create_person()
      pconf_person = create_confidant_person("PRIMARY")
      sconf_person = create_confidant_person("SECONDARY")

      {:ok, person: person, pconf_person: pconf_person, sconf_person: sconf_person}
    end

    test "Returns :ok for correct person", %{person: person} do
      assert :ok = ValidatePerson.validate(person)
    end

    test "Returns :error if person documents contains incorrect objects", %{person: person} do
      # two documents of the same type
      bad_person = Map.update!(person, "documents", &[%{"type" => "PASSPORT", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # document with type not from dictionary
      bad_person = Map.update!(person, "documents", &[%{"type" => "NOT_IN_DICTIONARY", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :ok for person without phones", %{person: person} do
      person = Map.drop(person, ["phones"])
      assert :ok = ValidatePerson.validate(person)
    end

    test "Returns :error if person phones contains incorrect objects", %{person: person} do
      # two phones of the same type
      bad_person = Map.update!(person, "phones", &[%{"type" => "MOBILE", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # phone with type not from dictionary
      bad_person = Map.update!(person, "phones", &[%{"type" => "NOT_FROM_DICTIONARY", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if emergency_contact phones contains incorrect objects", %{person: person} do
      # two phones of the same type
      bad_person = update_in(person["emergency_contact"]["phones"], &[%{"type" => "MOBILE", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # phone with type not from dictionary
      bad_person =
        update_in(person["emergency_contact"]["phones"], &[%{"type" => "NOT_FROM_DICTIONARY", "number" => 3} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if person authentication_methods contains incorrect objects", %{person: person} do
      # two correct auth methods
      bad_person = Map.update!(person, "authentication_methods", &[%{"type" => "OTP"} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # two auth methods of the same type
      bad_person = Map.update!(person, "authentication_methods", &[%{"type" => "OFFLINE"} | &1])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # auth method not from dictionary
      bad_person = Map.put(person, "authentication_methods", [%{"type" => "NOT_FROM_DICTIONARY"}])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :ok for correct person with primary confidant_person",
      %{person: person, pconf_person: pconf_person} do

      person = Map.put(person, "confidant_person", [pconf_person])
      assert :ok = ValidatePerson.validate(person)
    end

    test "Returns :ok for correct person with primary and secondary confidant_persons",
      %{person: person, pconf_person: pconf_person, sconf_person: sconf_person} do

      person = Map.put(person, "confidant_person", [pconf_person, sconf_person])
      assert :ok = ValidatePerson.validate(person)
    end

    test "Returns :error if confidant_person documents_person contains incorrect objects",
      %{person: person, pconf_person: pconf_person} do

        # two documents of the same type
      bad_pconf_person =
        Map.update!(pconf_person, "documents_person", &[%{"type" => "NATIONAL_ID", "number" => 5} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # document with type not from dictionary
      bad_pconf_person =
        Map.update!(pconf_person, "documents_person", &[%{"type" => "NOT_IN_DICTIONARY", "number" => 3} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :ok for correct person with primary confidant_person without phones",
      %{person: person, pconf_person: pconf_person} do

      pconf_person = Map.drop(pconf_person, ["phones"])
      person = Map.put(person, "confidant_person", [pconf_person])
      assert :ok = ValidatePerson.validate(person)
    end

    test "Returns :error if confidant_person phones contains incorrect objects",
      %{person: person, pconf_person: pconf_person} do

        # two phones of the same type
      bad_pconf_person = Map.update!(pconf_person, "phones", &[%{"type" => "MOBILE", "number" => 3} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # phone with type not from dictionary
      bad_pconf_person =
        Map.update!(pconf_person, "phones", &[%{"type" => "NOT_FROM_DICTIONARY", "number" => 3} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if there is two primary confidant_person", %{person: person, pconf_person: pconf_person} do
      bad_person = Map.put(person, "confidant_person", [pconf_person, pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if there is only secondary confidant_person",
      %{person: person, sconf_person: sconf_person} do

        bad_person = Map.put(person, "confidant_person", [sconf_person, sconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if there is more than 2 confidant_person",
      %{person: person, pconf_person: pconf_person, sconf_person: sconf_person} do

      bad_person = Map.put(person, "confidant_person", [pconf_person, sconf_person, pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end

    test "Returns :error if confidant_person documents_relationship contains incorrect objects",
      %{person: person, pconf_person: pconf_person} do

        # two documents of the same type
      bad_pconf_person =
        Map.update!(pconf_person, "documents_relationship", &[%{"type" => "CONFIDANT_CERTIFICATE", "number" => 5} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)

      # document with type not from dictionary
      bad_pconf_person =
        Map.update!(pconf_person, "documents_relationship", &[%{"type" => "NOT_IN_DICTIONARY", "number" => 3} | &1])
      bad_person = Map.put(person, "confidant_person", [bad_pconf_person])
      assert {:error, _} = ValidatePerson.validate(bad_person)
    end
  end

  describe "Test that ValidatePerson.validate/1 returns correct error statuses" do
    setup _context do
      insert(:il, :dictionary_phone_type)
      insert(:il, :dictionary_document_type)
      insert(:il, :dictionary_authentication_method)
      insert(:il, :dictionary_document_relationship_type)

      person = create_person()
      pconf_person = create_confidant_person("PRIMARY")
      sconf_person = create_confidant_person("SECONDARY")

      {:ok, person: person, pconf_person: pconf_person, sconf_person: sconf_person}
    end

    test "Error message if person documents contains duplicate objects", %{person: person} do
      # two documents of the same type
      bad_person = Map.update!(person, "documents", &[%{"type" => "PASSPORT", "number" => 3} | &1])
      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "Duplicate value 'PASSPORT'" == reason
      assert "#/person/documents/type" == path
    end

    test "Error message if person phones contains incorrect objects", %{person: person} do
      # phone with type not from dictionary
      bad_person = Map.update!(person, "phones", &[%{"type" => "NOT_FROM_DICTIONARY", "number" => 3} | &1])
      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "Value 'NOT_FROM_DICTIONARY' is not found in Dictionary" == reason
      assert "#/person/phones/type" == path
    end

    test "Error message if person authentication_methods contains incorrect objects", %{person: person} do
      # two correct auth methods
      bad_person = Map.update!(person, "authentication_methods", &[%{"type" => "OTP"} | &1])
      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "Must be one and only one authentication method." == reason
      assert "#/person/authentication_methods/type" == path

      # auth method not from dictionary
      bad_person = Map.put(person, "authentication_methods", [%{"type" => "NOT_FROM_DICTIONARY"}])
      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "Value 'NOT_FROM_DICTIONARY' is not found in Dictionary" == reason
      assert "#/person/authentication_methods/type" == path
    end

    test "Error message if there is only SECONDARY confidant_person",
      %{person: person, sconf_person: sconf_person} do

      bad_person = Map.put(person, "confidant_person", [sconf_person])
      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "'PRIMARY' is required" == reason
      assert "#/person/confidant_person/relation_type" == path
    end

    test "Error message if 1 of 2 confidant_person contains incorrect data",
      %{person: person, pconf_person: pconf_person, sconf_person: sconf_person} do

      # two documents of the same type
      bad_sconf_person =
        Map.update!(sconf_person, "documents_relationship", &[%{"type" => "CONFIDANT_CERTIFICATE", "number" => 5} | &1])
      bad_person = Map.put(person, "confidant_person", [pconf_person, bad_sconf_person])

      {:error, [{reason, path}]} = ValidatePerson.validate(bad_person)

      assert "Duplicate value 'CONFIDANT_CERTIFICATE'" == reason
      assert "#/person/confidant_person/documents_relationship/type" == path
    end
  end

  defp create_person do
    %{
      "documents" => [
        %{"type" => "PASSPORT", "number" => 1},
        %{"type" => "NATIONAL_ID", "number" => 2}
      ],
      "phones" => [
        %{"type" => "MOBILE", "number" => 1},
        %{"type" => "LAND_LINE", "number" => 2}
      ],
      "emergency_contact" => %{
        "phones" => [
          %{"type" => "MOBILE", "number" => 1},
          %{"type" => "LAND_LINE", "number" => 2}
        ]
      },
      "authentication_methods" => [
        # %{"type" => "OTP"},                  # only 1 of 2 at the same time
        %{"type" => "OFFLINE"}
      ],
      "confidant_person" => nil
    }
  end

  defp create_confidant_person(relation) when relation in ["PRIMARY", "SECONDARY"]  do
      %{
        "relation_type" => relation,
        "documents_person" => [
          %{"type" => "PASSPORT", "number" => 1},
          %{"type" => "NATIONAL_ID", "number" => 2}
        ],
        "phones" => [
          %{"type" => "MOBILE", "number" => 1},
          %{"type" => "LAND_LINE", "number" => 2}
        ],
        "documents_relationship" => [
          %{"type" => "DOCUMENT", "number" => 1},
          %{"type" => "COURT_DECISION", "number" => 2},
          %{"type" => "BIRTH_CERTIFICATE", "number" => 3},
          %{"type" => "CONFIDANT_CERTIFICATE", "number" => 4}
        ]
      }
  end
end
