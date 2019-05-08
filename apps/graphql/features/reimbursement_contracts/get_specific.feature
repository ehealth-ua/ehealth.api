Feature: Get specific reimbursement contract

  Scenario: Get toCreateRequestContent field
    Given the following legal entities exist:
      | databaseId                             | type       |
      | "923f79db-4539-499f-be03-6d2a5d3d881a" | "NHS"      |
      | "e04303a1-3c62-4b45-9288-1859c65c815f" | "PHARMACY" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employeeType |
      | "65735584-b938-4882-bab5-207cf2bda235" | "NHS_SIGNER" |
      | "d71eed0e-0760-4730-a616-b75ee642873b" | "OWNER"      |
    And the following divisions exist:
      | databaseId                             | type       | legalEntityId                          |
      | "308375d9-37f6-4a82-a4ed-1d6a840f06de" | "PHARMACY" | "e04303a1-3c62-4b45-9288-1859c65c815f" |
      | "37b78300-4185-48f2-a1a7-a51aad8f9a6b" | "PHARMACY" | "e04303a1-3c62-4b45-9288-1859c65c815f" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "1bd6bbb4-2783-4ce5-841c-4461b69426d6" | "DOCTOR"     | "e04303a1-3c62-4b45-9288-1859c65c815f" |
      | "d69fa719-5771-46aa-b07a-162abc6f155b" | "DOCTOR"     | "e04303a1-3c62-4b45-9288-1859c65c815f" |
    And the following medical programs exist:
      | databaseId                             |
      | "7ffdd3b4-a3c7-40a9-bc62-4c2bdc65deb5" |
    And a reimbursement contract with the following fields exist:
      | field                    | value                                                                             |
      | databaseId               | "ab9328f4-f9dc-4135-a126-2acc4ac4a1af"                                            |
      | contractNumber           | "0000-9EAX-XT7X-3115"                                                             |
      | contractorLegalEntityId  | "e04303a1-3c62-4b45-9288-1859c65c815f"                                            |
      | contractorOwnerId        | "d71eed0e-0760-4730-a616-b75ee642873b"                                            |
      | contractorPaymentDetails | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"} |
      | endDate                  | "2019-04-11"                                                                      |
      | idForm                   | "17"                                                                              |
      | issueCity                | "Київ"                                                                            |
      | medicalProgramId         | "7ffdd3b4-a3c7-40a9-bc62-4c2bdc65deb5"                                            |
      | nhsLegalEntityId         | "923f79db-4539-499f-be03-6d2a5d3d881a"                                            |
      | nhsPaymentMethod         | "prepayment"                                                                      |
      | nhsSignerBase            | "на підставі наказу"                                                              |
      | nhsSignerId              | "65735584-b938-4882-bab5-207cf2bda235"                                            |
      | startDate                | "2019-03-28"                                                                      |
    And the following contract divisions exist:
      | contractId                             | divisionId                             |
      | "ab9328f4-f9dc-4135-a126-2acc4ac4a1af" | "308375d9-37f6-4a82-a4ed-1d6a840f06de" |
      | "ab9328f4-f9dc-4135-a126-2acc4ac4a1af" | "37b78300-4185-48f2-a1a7-a51aad8f9a6b" |
    And the following dictionaries exist:
      | name                                  | values                                                                                                         | isActive |
      | "REIMBURSEMENT_CONTRACT_CONSENT_TEXT" | {"APPROVED": "Цією заявою Заявник висловлює бажання укласти договір про реімбурсацію..." } | true     |
    And my scope is "contract:read"
    And my client type is "NHS"
    And my client ID is "923f79db-4539-499f-be03-6d2a5d3d881a"
    When I request toCreateRequestContent of the reimbursement contract where databaseId is "ab9328f4-f9dc-4135-a126-2acc4ac4a1af"
    Then no errors should be returned
    And I should receive requested item
    And the toCreateRequestContent of the requested item should have the following fields:
      | field                         | value                                                                             |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про реімбурсацію..."       |
      | contract_number               | "0000-9EAX-XT7X-3115"                                                             |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                         |
      | contractor_divisions          | ["308375d9-37f6-4a82-a4ed-1d6a840f06de", "37b78300-4185-48f2-a1a7-a51aad8f9a6b"]  |
      | contractor_legal_entity_id    | "e04303a1-3c62-4b45-9288-1859c65c815f"                                            |
      | contractor_owner_id           | "d71eed0e-0760-4730-a616-b75ee642873b"                                            |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"} |
      | id_form                       | "17"                                                                              |
      | issue_city                    | "Київ"                                                                            |
      | medical_program_id            | "7ffdd3b4-a3c7-40a9-bc62-4c2bdc65deb5"                                            |
      | nhs_legal_entity_id           | "923f79db-4539-499f-be03-6d2a5d3d881a"                                            |
      | nhs_payment_method            | "prepayment"                                                                      |
      | nhs_signer_base               | "на підставі наказу"                                                              |
      | nhs_signer_id                 | "65735584-b938-4882-bab5-207cf2bda235"                                            |
      | parent_contract_id            | "ab9328f4-f9dc-4135-a126-2acc4ac4a1af"                                            |