Feature: Create capitation contract request

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
      | databaseId                             | type  |
      | "e8d4b752-79e7-4906-835f-42397ac78b56" | "MSP" |
    And the following divisions exist:
      | databaseId                             | type     | legalEntityId                          |
      | "47e56ff3-75ae-416b-8d35-4b4a8409e3c0" | "CLINIC" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f" | "CLINIC" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "f8feba9f-216d-4caf-bbaa-4228505351ad" | "OWNER"      | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "59c88952-ce62-47b9-b400-3a26ccde0cc9" | "DOCTOR"     | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "9071e3b7-1468-4322-8742-c3ccd571ef65" | "DOCTOR"     | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following capitation contracts exist:
      | contractNumber   | contractorLegalEntityId                |
      | "0000-AEHK-MPTX" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And my scope is "contract_request:create"
    And my client type is "NHS"
    And my client ID is "6696a798-22a7-4670-97b4-3b7d274f2d11"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    And I have a signed content with the following fields:
      | field                         | value                                                                                                                                                                                                                                                                                                                              |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про медичне обслуговування населення..."                                                                                                                                                                                                                                    |
      | contract_number               | "0000-AEHK-MPTX"                                                                                                                                                                                                                                                                                                                   |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                                                                                                                                                                                                                                                                          |
      | contractor_divisions          | ["47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f"]                                                                                                                                                                                                                                                   |
      | contractor_employee_divisions | [{"declaration_limit": 2000, "division_id": "47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "employee_id": "59c88952-ce62-47b9-b400-3a26ccde0cc9", "staff_units": 123.0}, {"declaration_limit": 2000, "division_id": "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f", "employee_id": "9071e3b7-1468-4322-8742-c3ccd571ef65", "staff_units": 123.0}] |
      | contractor_legal_entity_id    | "e8d4b752-79e7-4906-835f-42397ac78b56"                                                                                                                                                                                                                                                                                             |
      | contractor_owner_id           | "f8feba9f-216d-4caf-bbaa-4228505351ad"                                                                                                                                                                                                                                                                                             |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"}                                                                                                                                                                                                                                                  |
      | contractor_rmsp_amount        | 58813                                                                                                                                                                                                                                                                                                                              |
      | external_contractor_flag      | false                                                                                                                                                                                                                                                                                                                              |
      | id_form                       | "17"                                                                                                                                                                                                                                                                                                                               |
      | issue_city                    | "Київ"                                                                                                                                                                                                                                                                                                                             |
      | nhs_contract_price            | 105938.0                                                                                                                                                                                                                                                                                                                           |
      | nhs_legal_entity_id           | "6696a798-22a7-4670-97b4-3b7d274f2d11"                                                                                                                                                                                                                                                                                             |
      | nhs_payment_method            | "prepayment"                                                                                                                                                                                                                                                                                                                       |
      | nhs_signer_base               | "на підставі наказу"                                                                                                                                                                                                                                                                                                               |
      | nhs_signer_id                 | "2c5ef867-310e-42f4-a581-27613e3ac2aa"                                                                                                                                                                                                                                                                                             |
    And the following signatures was applied:
      | drfo         | edrpou       | surname    |
      | "1234567890" | "0987654321" | "ШЕВЧЕНКО" |
    When I create contract request with signed content and attributes:
      | type         | assigneeId                             |
      | "CAPITATION" | "becfe929-60c0-4731-b4d7-e72482ff84fd" |
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "APPROVED"

  Scenario: Successful creation with external contractors
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
      | databaseId                             | type  |
      | "e8d4b752-79e7-4906-835f-42397ac78b56" | "MSP" |
      | "deda8da0-1c50-481a-a800-467294eb4f2b" | "MSP" |
    And the following divisions exist:
      | databaseId                             | type     | legalEntityId                          |
      | "47e56ff3-75ae-416b-8d35-4b4a8409e3c0" | "CLINIC" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f" | "CLINIC" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following employees exist:
      | databaseId                             | employeeType | legalEntityId                          |
      | "f8feba9f-216d-4caf-bbaa-4228505351ad" | "OWNER"      | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "59c88952-ce62-47b9-b400-3a26ccde0cc9" | "DOCTOR"     | "e8d4b752-79e7-4906-835f-42397ac78b56" |
      | "9071e3b7-1468-4322-8742-c3ccd571ef65" | "DOCTOR"     | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And the following capitation contracts exist:
      | contractNumber   | contractorLegalEntityId                |
      | "0000-AEHK-MPTX" | "e8d4b752-79e7-4906-835f-42397ac78b56" |
    And my scope is "contract_request:create"
    And my client type is "NHS"
    And my client ID is "6696a798-22a7-4670-97b4-3b7d274f2d11"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    And I have a signed content with the following fields:
      | field                         | value                                                                                                                                                                                                                                                                                                                              |
      | consent_text                  | "Цією заявою Заявник висловлює бажання укласти договір про медичне обслуговування населення..."                                                                                                                                                                                                                                    |
      | contract_number               | "0000-AEHK-MPTX"                                                                                                                                                                                                                                                                                                                   |
      | contractor_base               | "на підставі закону про Медичне обслуговування населення"                                                                                                                                                                                                                                                                          |
      | contractor_divisions          | ["47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f"]                                                                                                                                                                                                                                                   |
      | contractor_employee_divisions | [{"declaration_limit": 2000, "division_id": "47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "employee_id": "59c88952-ce62-47b9-b400-3a26ccde0cc9", "staff_units": 123.0}, {"declaration_limit": 2000, "division_id": "0ffa3a6e-12d8-40d8-8c60-ee7bcd7ef32f", "employee_id": "9071e3b7-1468-4322-8742-c3ccd571ef65", "staff_units": 123.0}] |
      | contractor_legal_entity_id    | "e8d4b752-79e7-4906-835f-42397ac78b56"                                                                                                                                                                                                                                                                                             |
      | contractor_owner_id           | "f8feba9f-216d-4caf-bbaa-4228505351ad"                                                                                                                                                                                                                                                                                             |
      | contractor_payment_details    | {"MFO": "351005", "bank_name": "Банк номер 1", "payer_account": "32009102701026"}                                                                                                                                                                                                                                                  |
      | contractor_rmsp_amount        | 58813                                                                                                                                                                                                                                                                                                                              |
      | external_contractor_flag      | true                                                                                                                                                                                                                                                                                                                               |
      | external_contractors          | [{"contract": {"expires_at": "2020-03-27", "issued_at": "2019-03-28", "number": "1234567"}, "divisions": [{"id": "47e56ff3-75ae-416b-8d35-4b4a8409e3c0", "medical_service": "Послуга ПМД"}], "legal_entity_id": "deda8da0-1c50-481a-a800-467294eb4f2b"}]                                                                           |
      | id_form                       | "17"                                                                                                                                                                                                                                                                                                                               |
      | issue_city                    | "Київ"                                                                                                                                                                                                                                                                                                                             |
      | nhs_contract_price            | 105938.0                                                                                                                                                                                                                                                                                                                           |
      | nhs_legal_entity_id           | "6696a798-22a7-4670-97b4-3b7d274f2d11"                                                                                                                                                                                                                                                                                             |
      | nhs_payment_method            | "prepayment"                                                                                                                                                                                                                                                                                                                       |
      | nhs_signer_base               | "на підставі наказу"                                                                                                                                                                                                                                                                                                               |
      | nhs_signer_id                 | "2c5ef867-310e-42f4-a581-27613e3ac2aa"                                                                                                                                                                                                                                                                                             |
    And the following signatures was applied:
      | drfo         | edrpou       | surname    |
      | "1234567890" | "0987654321" | "ШЕВЧЕНКО" |
    When I create contract request with signed content and attributes:
      | type         | assigneeId                             |
      | "CAPITATION" | "becfe929-60c0-4731-b4d7-e72482ff84fd" |
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "APPROVED"

