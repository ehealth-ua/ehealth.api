Feature: Create employee request

  Scenario: Successful creation of a employee request
    Given my scope is "employee_request:create"
    And my client type is "NHS"
    And my client ID is "79409b40-2b1f-4dd1-a837-4dc6bee62641"
    And my consumer ID is "4c06601f-487d-40b7-93b0-4dc3d211d6ae"
    And the following legal entities exist:
      | databaseId                             |
      | "79409b40-2b1f-4dd1-a837-4dc6bee62641" |
    And the following divisions exist:
      | databaseId                             | legalEntityId                          |
      | "e2d291f8-ee93-48c2-9f08-6e0995b0b1d7" | "79409b40-2b1f-4dd1-a837-4dc6bee62641" |
    And the following party exist:
      | databaseId                             | taxId        |
      | "1d8bc549-d137-4759-8787-5562b1d0b7e0" | "3378115538" |
    And the following party user exist:
      | databaseId                             | partyId                                | userId                                 |
      | "d2b291b8-ae13-28c2-9a08-8e1255a0b1e6" | "1d8bc549-d137-4759-8787-5562b1d0b7e0" | "4c06601f-487d-40b7-93b0-4dc3d211d6ae" |
    When I create employee request with taxId "3378115538" and attributes:
      | field        | value                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
      | divisionId   | "e2d291f8-ee93-48c2-9f08-6e0995b0b1d7"                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
      | position     | "лікар"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
      | startDate    | "2018-08-07"                                                                                                                                                                                                                                                                                                                                                                                                                                                                             |
      | status       | "NEW"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
      | employeeType | "DOCTOR"                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
      | party        | {"first_name": "Петро","last_name": "Іванов","second_name": "Миколайович","birth_date": "1991-08-19","gender": "MALE","tax_id": "3378115538","no_tax_id": false,"email": "sp.virny@gmail.com","documents": [{"type": "PASSPORT","number": "120518"}], "phones": [{"type": "MOBILE", "number": "+380503410870"}], "about_myself": "biography", "working_experience": 5}                                                                                                                   |
      | doctor       | {"educations": [{"country": "UA", "city": "Київ", "institution_name": "Академія Богомольця", "issued_date": "2017-08-01", "diploma_number": "DD123543", "degree": "JUNIOR_EXPERT", "speciality": "Педіатр"}], "specialities": [{"speciality": "PEDIATRICIAN","speciality_officio": true,"level": "FIRST","qualification_type": "Присвоєння","attestation_name": "Академія Богомольця","attestation_date": "2017-08-04","valid_to_date": "2017-08-05","certificate_number": "AB/21331"}]} |
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "NEW"