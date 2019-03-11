Feature: Get all settlements

  Scenario: Request all items
    Given there are 2 settlements exist
    When I request first 10 settlements
    Then no errors should be returned
    And I should receive collection with 2 items

  Scenario Outline: Request items filtered by condition
    Given the following settlements exist:
      | databaseId     | <field>           |
      | <alternate_id> | <alternate_value> |
      | <expected_id>  | <expected_value>  |
    When I request first 10 settlements where <field> is <filter_value>
    Then no errors should be returned
    And I should receive collection with 1 item
    And the databaseId of the first item in the collection should be <expected_id>

    Examples:
      | field | filter_value | expected_value | alternate_value | expected_id                            | alternate_id                           |
      | name  | "вас"        | "ВАСИЛІВКА"    | "АНДРІЇВКА"     | "e63fb732-b3cd-4f88-a757-6f695ee34206" | "37a8934f-57e5-4c5a-8b29-6f0851d609e9" |

  Scenario Outline: Request items ordered by field values
    Given the following settlements exist:
      | <field>           |
      | <alternate_value> |
      | <expected_value>  |
    When I request first 10 settlements sorted by <field> in <direction> order
    Then no errors should be returned
    And I should receive collection with 2 items
    And the <field> of the first item in the collection should be <expected_value>

    Examples:
      | field         | direction  | expected_value                | alternate_value               |
      | mountainGroup | ascending  | false                         | true                          |
      | mountainGroup | descending | true                          | false                         |
      | name          | ascending  | "АНДРІЇВКА"                   | "ВАСИЛІВКА"                   |
      | name          | descending | "ВАСИЛІВКА"                   | "АНДРІЇВКА"                   |
      | insertedAt    | ascending  | "2017-01-28T06:00:27.000000Z" | "2018-12-24T10:30:01.000000Z" |
      | insertedAt    | descending | "2018-12-24T10:30:01.000000Z" | "2017-01-28T06:00:27.000000Z" |

  # TODO: move this into "get specific" feature
  Scenario Outline: Request one-to-one association fields
    Given the following <association_entity> exist:
      | databaseId       |
      | <association_id> |
    And the following settlements exist:
      | databaseId    | <association_field>Id |
      | <database_id> | <association_id>      |
    When I request databaseId of the <association_field> of the first 10 settlements
    Then no errors should be returned
    And I should receive collection with 1 item

    Examples:
      | database_id                            | association_entity | association_field | association_id                         |
      | "413f414d-9e18-4395-9490-4b176de836de" | regions            | region            | "244a7188-ef69-47b4-8d56-dfd1c7a8de02" |
      | "36c7858c-602f-4fca-b4fc-dc4d5274a28b" | districts          | district          | "d76b5fea-d254-4456-bb99-db767357eed7" |
      | "6a6d902e-bf21-44b0-b4d4-88e2e2e7a456" | settlements        | parentSettlement  | "812079e6-9c7f-4220-be37-3c380b388b4b" |

