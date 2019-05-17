Feature: Create reimbursement contract request

  Scenario: Successful creation
    Given the following legal entities exist:
      | databaseId                             | type  | edrpou       |
      | "6696a798-22a7-4670-97b4-3b7d274f2d11" | "NHS" | "0987654321" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "2c5ef867-310e-42f4-a581-27613e3ac2aa" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
      | "becfe929-60c0-4731-b4d7-e72482ff84fd" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
    And the following parties exist:
      | databaseId                             | taxId        | lastName   |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "1234567890" | "Шевченко" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "ae9ebf73-ec29-492c-9eb8-8ada2425eab2" |
    And the following legal entities exist:
      | databaseId                             | type       |
      | "e8d4b752-79e7-4906-835f-42397ac78b56" | "PHARMACY" |
    And the following divisions exist:
      | databaseId                             | type        | legalEntityId                          | dlsVerified |
      | "47e56ff3-75ae-416b-8d35-4b4a8409e3c0" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | true        |
      | "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | true        |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "f8feba9f-216d-4caf-bbaa-4228505351ad" | "OWNER"      | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following medical programs exist:
      | databaseId                             |
      | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the following reimbursement contracts exist:
      | databaseId                             | contractNumber   | contractorLegalEntityId                | medicalProgramId                       |
      | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2" | "0000-AEHK-MPTX" | "e8d4b752-79e7-4906-835f-42397ac78b56" | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the environment variable "DISPENSE_DIVISION_DLS_VERIFY" set to "true"
    And my scope is "contract_request:create"
    And my client type is "NHS"
    And my client ID is "6696a798-22a7-4670-97b4-3b7d274f2d11"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    And I have a signed content with the following fields:
      | field                         | value                                                                             |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про реімбурсацію..."       |
      | contract_number               | "0000-AEHK-MPTX"                                                                  |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                         |
      | contractor_divisions          | ["47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f"]  |
      | contractor_legal_entity_id    | "e8d4b752-79e7-4906-835f-42397ac78b56"                                            |
      | contractor_owner_id           | "f8feba9f-216d-4caf-bbaa-4228505351ad"                                            |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"} |
      | id_form                       | "17"                                                                              |
      | issue_city                    | "Київ"                                                                            |
      | medical_program_id            | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7"                                            |
      | nhs_legal_entity_id           | "6696a798-22a7-4670-97b4-3b7d274f2d11"                                            |
      | nhs_payment_method            | "prepayment"                                                                      |
      | nhs_signer_base               | "на підставі наказу"                                                              |
      | nhs_signer_id                 | "2c5ef867-310e-42f4-a581-27613e3ac2aa"                                            |
      | parent_contract_id            | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2"                                            |
    And the following signatures was applied:
      | drfo         | edrpou       | surname    |
      | "1234567890" | "0987654321" | "ШЕВЧЕНКО" |
    When I create contract request with signed content and attributes:
      | type            | assigneeId                             |
      | "REIMBURSEMENT" | "becfe929-60c0-4731-b4d7-e72482ff84fd" |
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "APPROVED"
    And the databaseId in the assignee of the requested item should be "becfe929-60c0-4731-b4d7-e72482ff84fd"

  Scenario: Create with divisions not passed DLS verification
    Given the following legal entities exist:
      | databaseId                             | type  | edrpou       |
      | "6696a798-22a7-4670-97b4-3b7d274f2d11" | "NHS" | "0987654321" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "2c5ef867-310e-42f4-a581-27613e3ac2aa" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
      | "becfe929-60c0-4731-b4d7-e72482ff84fd" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
    And the following parties exist:
      | databaseId                             | taxId        | lastName   |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "1234567890" | "Шевченко" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "ae9ebf73-ec29-492c-9eb8-8ada2425eab2" |
    And the following legal entities exist:
      | databaseId                             | type       |
      | "e8d4b752-79e7-4906-835f-42397ac78b56" | "PHARMACY" |
    And the following divisions exist:
      | databaseId                             | type        | legalEntityId                          | dlsVerified |
      | "47e56ff3-75ae-416b-8d35-4b4a8409e3c0" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | false       |
      | "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | null        |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "f8feba9f-216d-4caf-bbaa-4228505351ad" | "OWNER"      | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following medical programs exist:
      | databaseId                             |
      | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the following reimbursement contracts exist:
      | databaseId                             | contractNumber   | contractorLegalEntityId                | medicalProgramId                       |
      | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2" | "0000-AEHK-MPTX" | "e8d4b752-79e7-4906-835f-42397ac78b56" | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the environment variable "DISPENSE_DIVISION_DLS_VERIFY" set to "true"
    And my scope is "contract_request:create"
    And my client type is "NHS"
    And my client ID is "6696a798-22a7-4670-97b4-3b7d274f2d11"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    And I have a signed content with the following fields:
      | field                         | value                                                                             |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про реімбурсацію..."       |
      | contract_number               | "0000-AEHK-MPTX"                                                                  |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                         |
      | contractor_divisions          | ["47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f"]  |
      | contractor_legal_entity_id    | "e8d4b752-79e7-4906-835f-42397ac78b56"                                            |
      | contractor_owner_id           | "f8feba9f-216d-4caf-bbaa-4228505351ad"                                            |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"} |
      | id_form                       | "17"                                                                              |
      | issue_city                    | "Київ"                                                                            |
      | medical_program_id            | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7"                                            |
      | nhs_legal_entity_id           | "6696a798-22a7-4670-97b4-3b7d274f2d11"                                            |
      | nhs_payment_method            | "prepayment"                                                                      |
      | nhs_signer_base               | "на підставі наказу"                                                              |
      | nhs_signer_id                 | "2c5ef867-310e-42f4-a581-27613e3ac2aa"                                            |
      | parent_contract_id            | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2"                                            |
    And the following signatures was applied:
      | drfo         | edrpou       | surname    |
      | "1234567890" | "0987654321" | "ШЕВЧЕНКО" |
    When I create contract request with signed content and attributes:
      | type            | assigneeId                             |
      | "REIMBURSEMENT" | "becfe929-60c0-4731-b4d7-e72482ff84fd" |
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Create with disabled validation on division DLS verification
    Given the following legal entities exist:
      | databaseId                             | type  | edrpou       |
      | "6696a798-22a7-4670-97b4-3b7d274f2d11" | "NHS" | "0987654321" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "2c5ef867-310e-42f4-a581-27613e3ac2aa" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
      | "becfe929-60c0-4731-b4d7-e72482ff84fd" | "NHS"        | "6696a798-22a7-4670-97b4-3b7d274f2d11" |
    And the following parties exist:
      | databaseId                             | taxId        | lastName   |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "1234567890" | "Шевченко" |
    And the following party users exist:
      | partyId                                | userId                                 |
      | "1184f63e-a51b-4865-83b5-33479dc9816c" | "ae9ebf73-ec29-492c-9eb8-8ada2425eab2" |
    And the following legal entities exist:
      | databaseId                             | type       |
      | "e8d4b752-79e7-4906-835f-42397ac78b56" | "PHARMACY" |
    And the following divisions exist:
      | databaseId                             | type        | legalEntityId                          | dlsVerified |
      | "47e56ff3-75ae-416b-8d35-4b4a8409e3c0" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | false       |
      | "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f" | "DRUGSTORE" | "e8d4b752-79e7-4906-835f-42397ac78b56" | null        |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "f8feba9f-216d-4caf-bbaa-4228505351ad" | "OWNER"      | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following medical programs exist:
      | databaseId                             |
      | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the following reimbursement contracts exist:
      | databaseId                             | contractNumber   | contractorLegalEntityId                | medicalProgramId                       |
      | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2" | "0000-AEHK-MPTX" | "e8d4b752-79e7-4906-835f-42397ac78b56" | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7" |
    And the environment variable "DISPENSE_DIVISION_DLS_VERIFY" set to "false"
    And my scope is "contract_request:create"
    And my client type is "NHS"
    And my client ID is "6696a798-22a7-4670-97b4-3b7d274f2d11"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    And I have a signed content with the following fields:
      | field                         | value                                                                             |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про реімбурсацію..."       |
      | contract_number               | "0000-AEHK-MPTX"                                                                  |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                         |
      | contractor_divisions          | ["47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f"]  |
      | contractor_legal_entity_id    | "e8d4b752-79e7-4906-835f-42397ac78b56"                                            |
      | contractor_owner_id           | "f8feba9f-216d-4caf-bbaa-4228505351ad"                                            |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"} |
      | id_form                       | "17"                                                                              |
      | issue_city                    | "Київ"                                                                            |
      | medical_program_id            | "a56e0d0e-2678-4efe-908d-f9ceb793a3d7"                                            |
      | nhs_legal_entity_id           | "6696a798-22a7-4670-97b4-3b7d274f2d11"                                            |
      | nhs_payment_method            | "prepayment"                                                                      |
      | nhs_signer_base               | "на підставі наказу"                                                              |
      | nhs_signer_id                 | "2c5ef867-310e-42f4-a581-27613e3ac2aa"                                            |
      | parent_contract_id            | "fe4d0548-9085-411a-bcc1-951fdf5f0ee2"                                            |
    And the following signatures was applied:
      | drfo         | edrpou       | surname    |
      | "1234567890" | "0987654321" | "ШЕВЧЕНКО" |
    When I create contract request with signed content and attributes:
      | type            | assigneeId                             |
      | "REIMBURSEMENT" | "becfe929-60c0-4731-b4d7-e72482ff84fd" |
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "APPROVED"
    And the databaseId in the assignee of the requested item should be "becfe929-60c0-4731-b4d7-e72482ff84fd"
