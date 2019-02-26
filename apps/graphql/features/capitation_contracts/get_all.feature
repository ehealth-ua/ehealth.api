Feature: Get all capitation contracts

  Scenario: Request all capitation contracts with NHS client
    Given there are 2 capitation contracts exist
    And there are 10 reimbursement contracts exist
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 capitation contracts
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "c952510e-9384-465c-9f61-05de64a7918b" | "MSP" |
      | "bd4aa0e3-ad4a-4963-9b21-b53111e75525" | "MSP" |
    And the following capitation contracts exist:
      | databaseId                             | contractorLegalEntityId                |
      | "d830e2a9-5487-49e1-9ac8-010c98f91f69" | "c952510e-9384-465c-9f61-05de64a7918b" |
      | "0870e7e4-399a-4798-9f44-fdfdd24f382f" | "bd4aa0e3-ad4a-4963-9b21-b53111e75525" |
    And my scope is "contract:read"
    And my client type is "MSP"
    And my client ID is "c952510e-9384-465c-9f61-05de64a7918b"
    When I request first 10 capitation contracts
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "d830e2a9-5487-49e1-9ac8-010c98f91f69"

  Scenario: Request with incorrect client
    Given there are 2 capitation contracts exist
    And my scope is "contract:read"
    And my client type is "MIS"
    When I request first 10 capitation contracts
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following capitation contracts exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 capitation contracts where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field               | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId          | "74bc9df5-f551-41cd-b3a3-9933e2b21695" | "74bc9df5-f551-41cd-b3a3-9933e2b21695" | "9acc450a-7e23-40ab-8377-a6073f6b86a6" |
      | contractNumber      | "0000-ABEK-1234-5678"                  | "0000-ABEK-1234-5678"                  | "0000-MHPC-8765-4321"                  |
      | status              | "VERIFIED"                             | "VERIFIED"                             | "TERMINATED"                           |
      | startDate           | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate             | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | isSuspended         | false                                  | false                                  | true                                   |

  Scenario Outline: Request items filtered by condition on association
    Given the following <association_entity> exist:
      | databaseId                 | <field>           |
      | <alternate_association_id> | <alternate_value> |
      | <expected_association_id>  | <expected_value>  |
    And the following capitation contracts exist:
      | databaseId     | <association_field>Id      |
      | <alternate_id> | <alternate_association_id> |
      | <expected_id>  | <expected_association_id>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 capitation contracts where <field> of the associated <association_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | association_entity | association_field     | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           | expected_association_id                | alternate_association_id               |
      | legal entities     | contractorLegalEntity | databaseId   | "488b864e-9602-4994-9bdc-84fce28424ba" | "5ab2942c-449c-4756-9a7c-8079ca4b6cb8" | "c5ced316-16a7-4532-b84e-56f7b84e5579" | "5ab2942c-449c-4756-9a7c-8079ca4b6cb8" | "e0dff91c-747e-4d3b-96ed-eae9ba429eae" | "488b864e-9602-4994-9bdc-84fce28424ba" | "ecd4d90d-6831-4566-befa-e23e7f5f13e7" |
      | legal entities     | contractorLegalEntity | edrpou       | "12345"                                | "1234567890"                           | "0987654321"                           | "8278dc43-8260-43f9-88de-c60a2802df64" | "205bd220-d208-48ca-bed5-a5e700fb604a" | "2b5b2ea0-23a2-4ca5-85d8-b552e97b2c76" | "2845d951-65e9-42b7-96b5-21d4d8ffcf60" |
      | legal entities     | contractorLegalEntity | name         | "acme"                                 | "Acme Corporation"                     | "Ajax LLC"                             | "a2c6fbd6-a5e8-4269-bcd8-6b7fc6b683d1" | "7e90abcd-b734-47d1-b596-4d407407218b" | "f696dbed-e733-4886-9985-ad4ec301686b" | "cdde5d03-00f0-482c-8993-4d98c5178924" |
      | legal entities     | contractorLegalEntity | nhsReviewed  | false                                  | false                                  | true                                   | "611a50e5-94c8-4867-8675-f60bfc6c3f13" | "66f1dfc2-94f1-46dd-8a07-2dde81d82f72" | "1744218d-6444-4291-8732-9c2921b1555a" | "22cedeab-28f7-4a05-8ecf-db4074b3bb15" |
      | legal entities     | contractorLegalEntity | nhsVerified  | true                                   | true                                   | false                                  | "4f299fab-17a6-4bd5-bc1f-519efa5e8b17" | "6ab65420-1ad2-4089-b9ff-46310cb95b97" | "4ab5827c-6ee6-40bc-83f9-274ccb6073a4" | "1b1e299c-c4f6-47e6-8b33-2d8b2f0f226f" |

  Scenario Outline: Request items ordered by field values
    Given the following capitation contracts exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 capitation contracts sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field       | direction  | expected_value               | alternate_value              |
      | endDate     | ascending  | "2018-07-12"                 | "2018-11-22"                 |
      | endDate     | descending | "2018-11-22"                 | "2018-07-12"                 |
      | insertedAt  | ascending  | "2016-01-15T14:00:00.000000" | "2017-05-13T17:00:00.000000" |
      | insertedAt  | descending | "2017-05-13T17:00:00.000000" | "2016-01-15T14:00:00.000000" |
      | isSuspended | ascending  | false                        | true                         |
      | isSuspended | descending | true                         | false                        |
      | startDate   | ascending  | "2016-08-01"                 | "2016-10-30"                 |
      | startDate   | descending | "2016-10-30"                 | "2016-08-01"                 |
      | status      | ascending  | "TERMINATED"                 | "VERIFIED"                   |
      | status      | descending | "VERIFIED"                   | "TERMINATED"                 |
