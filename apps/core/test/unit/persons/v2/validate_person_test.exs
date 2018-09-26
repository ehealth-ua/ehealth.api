defmodule Core.Persons.V2.ValidatorTest do
  @moduledoc false

  use Core.ConnCase
  alias Core.Persons.V2.Validator
  alias Core.ValidationError

  @today_date Date.to_string(Date.utc_today())

  describe "Additional validation of JSON request: Validator.validate/1" do
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
      assert :ok = Validator.validate(person)
    end

    test "Returns :ok for correct person with NATIONAL_ID document", %{person: person} do
      person =
        person
        |> Map.put("documents", [%{"type" => "NATIONAL_ID", "number" => "1234567"}])

      assert :ok == Validator.validate(person)
    end

    test "Returns :error if person documents contains incorrect objects", %{person: person} do
      # two documents of the same type
      invalid_person = Map.update!(person, "documents", &[%{"type" => "PASSPORT", "number" => 3} | &1])

      assert {:error,
              [
                {%{description: "No duplicate values.", params: ["PASSPORT"], rule: :invalid},
                 "$.person.documents[1].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :ok for person without phones", %{person: person} do
      person = Map.drop(person, ["phones"])
      assert :ok = Validator.validate(person)
    end

    test "Returns error if person phones contains incorrect objects", %{person: person} do
      # two phones of the same type
      invalid_person = Map.update!(person, "phones", &[%{"type" => "MOBILE", "number" => 3} | &1])

      assert {:error,
              [
                {%{
                   description: "No duplicate values.",
                   params: ["MOBILE"],
                   rule: :invalid
                 }, "$.person.phones[1].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :error if emergency_contact phones contains incorrect objects", %{person: person} do
      # two phones of the same type
      invalid_person = update_in(person["emergency_contact"]["phones"], &[%{"type" => "MOBILE", "number" => 3} | &1])

      assert {:error,
              [
                {%{
                   description: "No duplicate values.",
                   params: ["MOBILE"],
                   rule: :invalid
                 }, "$.person.emergency_contact.phones[1].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :error if person authentication_methods contains incorrect objects", %{person: person} do
      # two correct auth methods
      invalid_person = Map.update!(person, "authentication_methods", &[%{"type" => "OTP"} | &1])

      assert {:error,
              [
                {%{
                   description: "Must be one and only one authentication method.",
                   params: [],
                   rule: :invalid
                 }, "$.person.authentication_methods[0].type"}
              ]} = Validator.validate(invalid_person)

      # two auth methods of the same type
      invalid_person = Map.update!(person, "authentication_methods", &[%{"type" => "OFFLINE"} | &1])

      assert {:error,
              [
                {%{
                   description: "Must be one and only one authentication method.",
                   params: [],
                   rule: :invalid
                 }, "$.person.authentication_methods[0].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :ok for correct person with primary confidant_person", %{person: person, pconf_person: pconf_person} do
      person = Map.put(person, "confidant_person", [pconf_person])
      assert :ok = Validator.validate(person)
    end

    test "Returns :ok for correct person with primary and secondary confidant_persons", %{
      person: person,
      pconf_person: pconf_person,
      sconf_person: sconf_person
    } do
      person = Map.put(person, "confidant_person", [pconf_person, sconf_person])
      assert :ok = Validator.validate(person)
    end

    test "Returns :error if confidant_person documents_person contains incorrect objects", %{
      person: person,
      pconf_person: pconf_person
    } do
      # two documents of the same type
      invalid_pconf_person =
        Map.update!(pconf_person, "documents_person", &[%{"type" => "NATIONAL_ID", "number" => 5} | &1])

      invalid_person = Map.put(person, "confidant_person", [invalid_pconf_person])

      assert {:error,
              [
                {%{
                   description: "No duplicate values.",
                   params: ["NATIONAL_ID"],
                   rule: :invalid
                 }, "$.person.confidant_person[0].documents_person[2].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :ok for correct person with primary confidant_person without phones", %{
      person: person,
      pconf_person: pconf_person
    } do
      pconf_person = Map.drop(pconf_person, ["phones"])
      person = Map.put(person, "confidant_person", [pconf_person])
      assert :ok = Validator.validate(person)
    end

    test "Returns :error if confidant_person phones contains incorrect objects", %{
      person: person,
      pconf_person: pconf_person
    } do
      # two phones of the same type
      invalid_pconf_person = Map.update!(pconf_person, "phones", &[%{"type" => "MOBILE", "number" => 3} | &1])
      invalid_person = Map.put(person, "confidant_person", [invalid_pconf_person])

      assert {:error,
              [
                {%{description: "No duplicate values.", params: ["MOBILE"], rule: :invalid},
                 "$.person.confidant_person[0].phones[1].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Returns :error if there is two primary confidant_person", %{person: person, pconf_person: pconf_person} do
      invalid_person = Map.put(person, "confidant_person", [pconf_person, pconf_person])
      assert {:error, _} = Validator.validate(invalid_person)
    end

    test "Returns :error if there is only secondary confidant_person", %{person: person, sconf_person: sconf_person} do
      invalid_person = Map.put(person, "confidant_person", [sconf_person, sconf_person])
      assert {:error, _} = Validator.validate(invalid_person)
    end

    test "Returns :error if there is more than 2 confidant_person", %{
      person: person,
      pconf_person: pconf_person,
      sconf_person: sconf_person
    } do
      invalid_person = Map.put(person, "confidant_person", [pconf_person, sconf_person, pconf_person])
      assert {:error, _} = Validator.validate(invalid_person)
    end

    test "Returns :error if confidant_person documents_relationship contains incorrect objects", %{
      person: person,
      pconf_person: pconf_person
    } do
      # two documents of the same type
      invalid_pconf_person =
        Map.update!(pconf_person, "documents_relationship", &[%{"type" => "CONFIDANT_CERTIFICATE", "number" => 5} | &1])

      invalid_person = Map.put(person, "confidant_person", [invalid_pconf_person])

      assert {:error,
              [
                {%{
                   description: "No duplicate values.",
                   params: ["CONFIDANT_CERTIFICATE"],
                   rule: :invalid
                 }, "$.person.confidant_person[0].documents_relationship[4].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "returns :ok if confidant_person is empty list", %{person: person} do
      person = Map.put(person, "confidant_person", [])
      assert :ok = Validator.validate(person)
    end

    test "returns :ok if confidant_person is nil", %{person: person} do
      person = Map.put(person, "confidant_person", nil)
      assert :ok = Validator.validate(person)
    end
  end

  describe "Test that Validator.validate/1 returns correct error statuses" do
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
      invalid_person = Map.update!(person, "documents", &[%{"type" => "PASSPORT", "number" => 3} | &1])
      {:error, [{rules, path}]} = Validator.validate(invalid_person)

      assert %{description: "No duplicate values.", params: ["PASSPORT"], rule: :invalid} == rules
      assert "$.person.documents[1].type" == path
    end

    test "Error message if person authentication_methods contains incorrect objects", %{person: person} do
      # two correct auth methods
      invalid_person = Map.update!(person, "authentication_methods", &[%{"type" => "OTP"} | &1])

      assert {:error,
              [
                {%{
                   description: "Must be one and only one authentication method.",
                   params: [],
                   rule: :invalid
                 }, "$.person.authentication_methods[0].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Error message if there is only SECONDARY confidant_person", %{person: person, sconf_person: sconf_person} do
      invalid_person = Map.put(person, "confidant_person", [sconf_person])

      assert {:error,
              [
                {%{description: "Must contain required item.", params: ["PRIMARY"], rule: :invalid},
                 "$.person.confidant_person[].relation_type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Error message if 1 of 2 confidant_person contains incorrect data", %{
      person: person,
      pconf_person: pconf_person,
      sconf_person: sconf_person
    } do
      # two documents of the same type
      invalid_sconf_person =
        Map.update!(sconf_person, "documents_relationship", &[%{"type" => "CONFIDANT_CERTIFICATE", "number" => 5} | &1])

      invalid_person = Map.put(person, "confidant_person", [pconf_person, invalid_sconf_person])

      assert {:error,
              [
                {%{
                   description: "No duplicate values.",
                   params: ["CONFIDANT_CERTIFICATE"],
                   rule: :invalid
                 }, "$.person.confidant_person[1].documents_relationship[4].type"}
              ]} = Validator.validate(invalid_person)
    end

    test "Success on valid birth certificate number", %{person: person} do
      person = Map.put(person, "documents", [create_birth_certificate("І--АМ№179540")])
      assert :ok = Validator.validate(person)
    end

    test "Error on age smaller than 14 without birth certificate", %{person: person} do
      person = %{person | "birth_date" => @today_date, "unzr" => "#{String.replace(@today_date, "-", "")}-00000"}

      {:error, [{rules, _path}]} = Validator.validate(person)
      assert %{description: "Must contain required item.", params: ["BIRTH_CERTIFICATE"], rule: :invalid} == rules
    end

    test "Error on invalid unzr after birthdate", %{person: person} do
      person = %{person | "birth_date" => @today_date, "unzr" => "#{String.replace(@today_date, "-", "")}-5numbers"}

      {:error, [{rules, _path}]} = Validator.validate(person)
      assert %{rule: :invalid, description: "Birthdate or unzr is not correct", params: ["unzr"]} == rules
    end

    test "Error on invalid unzr birthdate not match", %{person: person} do
      person = %{person | "birth_date" => @today_date, "unzr" => "20160303-01234"}

      {:error, [{rules, _path}]} = Validator.validate(person)
      assert %{rule: :invalid, description: "Birthdate or unzr is not correct", params: ["unzr"]} == rules
    end

    test "Error on no unzr when NATIONAL_ID document", %{person: person} do
      person =
        person
        |> Map.delete("unzr")
        |> Map.put("documents", [%{"type" => "NATIONAL_ID", "number" => "1234567"}])

      {:error, [{rules, _path}]} = Validator.validate(person)

      assert %{rule: :invalid, description: "unzr is mandatory for document type NATIONAL_ID", params: ["unzr"]} ==
               rules
    end

    test "Error on invalid birth certificate number", %{person: person} do
      person = Map.put(person, "documents", [create_birth_certificate("I$-HM083557")])

      assert {:error,
              [
                {%{description: "Birth certificate number is not valid", params: ["BIRTH_CERTIFICATE"], rule: :invalid},
                 _path}
              ]} = Validator.validate(person)
    end
  end

  describe "validate no_tax_id" do
    test "no_tax_id true and tax_id does is nil" do
      person = %{"no_tax_id" => true, "tax_id" => nil}
      assert :ok == Validator.validate_tax_id(person)
    end

    test "no_tax_id true and tax_id does not exists" do
      person = %{"no_tax_id" => true}
      assert :ok == Validator.validate_tax_id(person)
    end

    test "no_tax_id false and tax_id exists" do
      person = %{"no_tax_id" => true, "tax_id" => nil}
      assert :ok == Validator.validate_tax_id(person)
    end

    test "no_tax_id false and tax_id does not  exists" do
      person = %{"no_tax_id" => false}

      assert %ValidationError{
               description: "Only persons who refused the tax_id could be without tax_id",
               params: ["tax_id"],
               path: "$.person.tax_id"
             } = Validator.validate_tax_id(person)
    end

    test "no_tax_id true and tax_id exists" do
      person = %{"no_tax_id" => true, "tax_id" => "01234"}

      assert %ValidationError{
               description: "Persons who refused the tax_id should be without tax_id",
               params: ["no_tax_id"],
               path: "$.person.tax_id"
             } = Validator.validate_tax_id(person)
    end
  end

  describe "validates birth certificate number" do
    test "passes" do
      valid_numbers = [
        "серія1МИ№052966",
        "І- ТП № 242141",
        "ІБК№;??%:",
        "ІСГ/178961",
        "КІ3215**",
        "№547./1/А"
      ]

      for number <- valid_numbers do
        person = create_person(%{"birth_date" => @today_date, "documents" => [create_birth_certificate(number)]})

        assert :ok == Validator.validate_birth_certificate_number(person)
      end
    end

    test "fails" do
      invalid_numbers = [
        "се$рія1МИ№052966",
        "І-ТП &№ 242141",
        "ІЖС№0^24825"
      ]

      for number <- invalid_numbers do
        assert %ValidationError{
                 description: "Birth certificate number is not valid",
                 params: ["BIRTH_CERTIFICATE"],
                 path: "$.person.documents[0].number",
                 rule: :invalid
               } =
                 :person
                 |> string_params_for(birth_date: @today_date, documents: [create_birth_certificate(number)])
                 |> Validator.validate_birth_certificate_number()
      end
    end
  end

  defp create_person(merge_data \\ %{}) do
    Map.merge(
      %{
        "birth_date" => "2000-01-01",
        "unzr" => "20000101-00000",
        "no_tax_id" => true,
        "documents" => [
          %{"type" => "PASSPORT", "number" => "ЇЇ012345"},
          %{"type" => "REFUGEE_CERTIFICATE", "number" => "ЇЇ012345"}
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
        ]
      },
      merge_data
    )
  end

  defp create_confidant_person(relation) when relation in ["PRIMARY", "SECONDARY"] do
    %{
      "relation_type" => relation,
      "documents_person" => [
        %{"type" => "REFUGEE_CERTIFICATE", "number" => "ЇЇ012345"},
        %{"type" => "NATIONAL_ID", "number" => "20180925-01234"}
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

  defp create_birth_certificate(number), do: %{"type" => "BIRTH_CERTIFICATE", "number" => number}
end
