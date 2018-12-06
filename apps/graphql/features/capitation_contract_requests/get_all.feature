Feature: Get all capitation contract requests

  Scenario: Request all items with NHS client
    Given there are 2 capitation contract requests exist
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request belonging items with MSP client
    Given the following legal entities exist:
      | databaseId                             | type   |
      | "07e526e1-077f-4327-aaad-438b7371924d" | "MSP"  |
      | "72f7a4dd-e3b8-4db7-834a-71e500227eef" | "MSP"  |
    And the following capitation contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "837c8f92-239e-41b8-aa94-3c812738b677" | "07e526e1-077f-4327-aaad-438b7371924d" |
      | "215d322f-c518-4d79-846a-ce81e9152a29" | "72f7a4dd-e3b8-4db7-834a-71e500227eef" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    And my client ID is "07e526e1-077f-4327-aaad-438b7371924d"
    When I request first 10 capitation contract requests
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be "837c8f92-239e-41b8-aa94-3c812738b677"

  Scenario: Request with incorrect client
    Given there are 2 capitation contract requests exist
    And my scope is "contract_request:read"
    And my client type is "MIS"
    When I request first 10 capitation contract requests
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following capitation contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field          | filter_value                           | expected_value                         | alternate_value                        |
      | databaseId     | "d19255a9-4703-49a2-9820-215dceda0ff4" | "d19255a9-4703-49a2-9820-215dceda0ff4" | "06ad0e9a-9cda-4751-84ec-02cd962999eb" |
      | contractNumber | "0000-AEHK-1234-5678"                  | "0000-AEHK-1234-5678"                  | "0000-MPTX-8765-4321"                  |
      | status         | "NEW"                                  | "NEW"                                  | "APPROWED"                             |
      | startDate      | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |
      | endDate        | "2018-05-23/2018-10-15"                | "2018-07-12"                           | "2018-11-22"                           |

  Scenario Outline: Request items ordered by field values
    Given the following capitation contract requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request first 10 capitation contract requests sorted by <field> in <direction> order
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
