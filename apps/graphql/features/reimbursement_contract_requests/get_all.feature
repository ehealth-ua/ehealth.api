Feature: Get all reimbursement contract requests

  Scenario: Request all items with NHS client
    Given there are 2 reimbursement contract requests exist
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "d3cc177d-8834-41ab-bec6-0dcd1bebaff8" | "MSP" |
      | "2bf7f226-078f-45db-8d47-ff7fe9f1397d" | "MSP" |
    And the following reimbursement contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "14d18157-3f26-45b0-b034-9bd8180eb469" | "d3cc177d-8834-41ab-bec6-0dcd1bebaff8" |
      | "3011e1c9-07b2-4c01-886e-f0b85b665297" | "2bf7f226-078f-45db-8d47-ff7fe9f1397d" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    And my client ID is "d3cc177d-8834-41ab-bec6-0dcd1bebaff8"
    When I request first 10 reimbursement contract requests
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "14d18157-3f26-45b0-b034-9bd8180eb469"

  Scenario: Request with incorrect client
    Given there are 2 reimbursement contract requests exist
    And my scope is "contract_request:read"
    And my client type is "MIS"
    When I request first 10 reimbursement contract requests
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following reimbursement contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field          | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId     | "92c5a8c1-1df2-4dc4-abf2-c37cfc6dbad4" | "92c5a8c1-1df2-4dc4-abf2-c37cfc6dbad4" | "ae495e7c-6398-4f4b-905f-9425375b5b5c" |
      | contractNumber | "0000-AEHK-1234-5678"                  | "0000-AEHK-1234-5678"                  | "0000-MPTX-8765-4321"                  |
      | status         | "NEW"                                  | "NEW"                                  | "APPROWED"                             |
      | startDate      | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate        | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    And the following reimbursement contract requests exist:
      | <association_field>Id |
      | <alternate_id>        |
      | <expected_id>         |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> in the <association_field> of the first item in the collection should be <expected_value>

    Examples:
      | association_entity | association_field     | field       | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | legal entities     | contractorLegalEntity | databaseId  | "ac972e99-2e1e-4ccc-ba45-99aa48687db8" | "ac972e99-2e1e-4ccc-ba45-99aa48687db8" | "28cf3260-7b80-442c-9875-e01aa89e85c0" | "ac972e99-2e1e-4ccc-ba45-99aa48687db8" | "28cf3260-7b80-442c-9875-e01aa89e85c0" |
      | legal entities     | contractorLegalEntity | edrpou      | "1234567890"                           | "1234567890"                           | "0987654321"                           | "66314869-66f1-45c2-948d-531491f6b17c" | "09bd6490-d4ff-4201-be77-df8b88eb3d04" |
      | legal entities     | contractorLegalEntity | nhsReviewed | false                                  | false                                  | true                                   | "07b1ecef-81ea-47f8-b16a-e394920a3290" | "fb2f0f53-492d-477d-b62b-bc428da63110" |
      | legal entities     | contractorLegalEntity | nhsVerified | true                                   | true                                   | false                                  | "f2f1d6a0-c4d2-4e61-a2c2-adad776d6cce" | "8f260981-0aeb-4d18-a426-18e029becd7b" |
      | medical programs   | medicalProgram        | databaseId  | "bd9c7e84-2fff-4d08-9a95-2e774b34241e" | "bd9c7e84-2fff-4d08-9a95-2e774b34241e" | "1e181257-aa03-4227-9f6b-cf04471a9391" | "bd9c7e84-2fff-4d08-9a95-2e774b34241e" | "1e181257-aa03-4227-9f6b-cf04471a9391" |
      | medical programs   | medicalProgram        | name        | "доступні"                             | "Доступні ліки"                        | "Безкоштовні вакцини"                  | "9d8f5f20-6857-4167-9776-95b873434abd" | "bd75746d-fde7-4064-9a13-57826ce7e2cd" |
      | medical programs   | medicalProgram        | isActive    | true                                   | true                                   | false                                  | "fcfcf8a7-ffef-4708-98b2-3cd9e0718d33" | "cc362c95-f839-4bae-b248-b8ca747c0d99" |

  Scenario: Request items filtered by assignee name
    Given the following parties exist:
      | databaseId                             | firstName | lastName      | secondName   |
      | "bafb2171-de1a-4ac2-9620-fe66f3c7be04" | "Едуард"  | "Островський" | "Олегович"   |
      | "3c6fb524-294b-4426-8e26-83991983a1ea" | "Олег"    | "Островський" | "Едуардович" |
    And the following employees exist:
      | databaseId                             | employeeType | partyId                                |
      | "4075bfb3-8814-43f4-a868-3541070f26fe" | "NHS"        | "bafb2171-de1a-4ac2-9620-fe66f3c7be04" |
      | "ca404f1a-d410-4ad7-ac73-40ee8457a790" | "NHS"        | "3c6fb524-294b-4426-8e26-83991983a1ea" |
    And the following reimbursement contract requests exist:
      | databaseId                             | assigneeId                             |
      | "d6b1c1b8-193f-4495-975b-66ea9028e422" | "4075bfb3-8814-43f4-a868-3541070f26fe" |
      | "fe577303-8a1b-45b0-b339-272274d5aac9" | "ca404f1a-d410-4ad7-ac73-40ee8457a790" |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests where assigneeName is "Островський Олег Едуардович"
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId in the assignee of the first item in the collection should be "ca404f1a-d410-4ad7-ac73-40ee8457a790"

  Scenario Outline: Request items ordered by field values
    Given the following reimbursement contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contract requests sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field      | direction  | expected_value               | alternate_value              |
      | endDate    | ascending  | "2018-07-12"                 | "2018-11-22"                 |
      | endDate    | descending | "2018-11-22"                 | "2018-07-12"                 |
      | insertedAt | ascending  | "2016-01-15T14:00:00.000000" | "2017-05-13T17:00:00.000000" |
      | insertedAt | descending | "2017-05-13T17:00:00.000000" | "2016-01-15T14:00:00.000000" |
      | startDate  | ascending  | "2016-08-01"                 | "2016-10-30"                 |
      | startDate  | descending | "2016-10-30"                 | "2016-08-01"                 |

