Feature: Get all employee requests

  Scenario: Request all items with NHS client
    Given there are 2 employee requests exist
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request first 10 employee requests
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request with incorrect client
    Given there are 2 employee request exist
    And my scope is "employee_request:read"
    And my client type is "MIS"
    When I request first 10 employee requests
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following employee requests exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request first 10 employee requests where <filter_field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field      | filter_field    | filter_value                                                       | expected_value                                              | alternate_value                                             | expected_id                            | alternate_id                           |
      | status     | status          | "APPROVED"                                                         | "APPROVED"                                                  | "REJECTED"                                                  | "f93dcf7e-bc30-4cf0-8f8a-f70d2f1ef209" | "25a0ac46-0c83-4c37-b798-7b90cee1d7fa" |
      | insertedAt | insertedAt      | "2019-01-01T00:00:00.000000Z/2019-01-10T00:00:00.000000Z"          | "2019-01-05T00:00:00.000000Z"                               | "2019-02-10T00:00:00.000000Z"                               | "b04cd9a4-66ba-44e7-8bbb-7f70c11158d0" | "34e59e35-8ad4-4e02-8174-858ba324d76b" |
      | data       | email           | "sample@mail.com"                                                  | {"party": {"email": "sample@mail.com"}}                     | {"party": {"email": "wrong@mail.com"}}                      | "70c18fa8-9c1f-416a-8438-0212a5acf4d8" | "25276bdc-4d99-4e3e-bb5d-19d394e48252" |
      | data       | legalEntityId   | "TGVnYWxFbnRpdHk6MTA4YmJjYzktNTFjYy00MmM1LTkxYWMtN2NkYzk5ZTA3YmU5" | {"legal_entity_id": "108bbcc9-51cc-42c5-91ac-7cdc99e07be9"} | {"legal_entity_id": "9a44df9d-b8c4-4ada-a99b-dca10550736d"} | "8623670a-9519-4e8f-bd67-fa91aef8a41a" | "06d083ac-6d58-438c-bd7d-70fba0aab816" |

  Scenario Outline: Request items ordered by field values
    Given the following employee requests exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request first 10 employee requests sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field        | direction  | expected_value                | alternate_value               |
      | insertedAt   | ascending  | "2017-07-14T19:25:38.000000Z" | "2018-09-27T18:22:20.000000Z" |
      | insertedAt   | descending | "2018-09-27T18:22:20.000000Z" | "2017-07-14T19:25:38.000000Z" |
      | status       | ascending  | "APPROVED"                    | "REJECTED"                    |
      | status       | descending | "REJECTED"                    | "APPROVED"                    |

  Scenario Outline: Request items ordered by full name
    Given the following employee requests exist:
      | data                                                                                                                          |
      | {"party": {"first_name": <first_name>, "last_name": <last_name>, "second_name": <second_name>}}                               |
      | {"party": {"first_name": <alternate_first_name>, "last_name": <alternate_last_name>, "second_name": <alternate_second_name>}} |
    And my scope is "employee_request:read"
    And my client type is "NHS"
    When I request first 10 employee requests sorted by fullName in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the lastName of the first item in the collection should be <last_name>

    Examples:
      | direction  | first_name | last_name | second_name | alternate_first_name | alternate_last_name | alternate_second_name |
      | ascending  | "Антон"    | "Антонов" | "Антонович" | "Борис"              | "Борисов"           | "Борисович"           |
      | descending | "Борис"    | "Борисов" | "Борисович" | "Антон"              | "Антонов"           | "Антонович"           |
