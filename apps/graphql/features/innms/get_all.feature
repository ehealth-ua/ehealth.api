Feature: Get all INNMs

  Scenario: Request all items with NHS client
    Given there are 2 INNMs exist
    And my scope is "innm:read"
    And my client type is "NHS"
    When I request first 10 INNMs
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario: Request with incorrect client
    Given there are 2 INNMs exist
    And my scope is "innm:read"
    And my client type is "MIS"
    When I request first 10 INNMs
    Then the "FORBIDDEN" error should be returned
    And I should not receive any collection items

  Scenario Outline: Request items filtered by condition
    Given the following INNMs exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    And my scope is "innm:read"
    And my client type is "NHS"
    When I request first 10 INNMs where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field        | filter_value                           | expected_value                         | alternate_value                        | expected_id                            | alternate_id                           |
      | databaseId   | "01c473f8-8cd7-487d-bfec-25f3756a6d41" | "01c473f8-8cd7-487d-bfec-25f3756a6d41" | "498c0897-efd0-4424-a9cd-284383e8df06" | "01c473f8-8cd7-487d-bfec-25f3756a6d41" | "498c0897-efd0-4424-a9cd-284383e8df06" |
      | sctid        | "12345678"                             | "12345678"                             | "87654321"                             | "39c05355-aceb-44ad-b71a-fd7c16c92afd" | "3ca7f7bc-0ce9-4096-81da-415d9fe8e449" |
      | name         | "гліцерин"                             | "Нітрогліцерин"                        | "Преднизолон"                          | "cb1f00a2-d704-4bcd-918a-4c050833074b" | "672385d3-e353-4521-b8ed-84c88bbaf47d" |
      | nameOriginal | "glycerin"                             | "Nitroglycerin"                        | "Prednisolonum"                        | "0accfbf6-6ae2-476d-8e3b-959352a559a4" | "d249d876-ac31-4898-8fc2-f6d9427e2098" |
      | isActive     | true                                   | true                                   | false                                  | "a7090b74-9d61-4164-9381-19d2bdbe778e" | "f40fae3e-203a-4b24-b803-26506564277b" |

  Scenario Outline: Request items ordered by field values
    Given the following INNMs exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    And my scope is "innm:read"
    And my client type is "NHS"
    When I request first 10 INNMs sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field        | direction  | expected_value                | alternate_value               |
      | insertedAt   | ascending  | "2017-07-14T19:25:38.000000Z" | "2018-09-27T18:22:20.000000Z" |
      | insertedAt   | descending | "2018-09-27T18:22:20.000000Z" | "2017-07-14T19:25:38.000000Z" |
