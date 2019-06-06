Feature: Update service

  Scenario Outline: Successful update
    Given the following services exist:
      | databaseId    | requestAllowed   |
      | <database_id> | <requestAllowed> |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I update the <field> with <next_value> in the service where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <next_value>

    Examples:
      | database_id                            | field          | next_value | requestAllowed |
      | "3b1a0ad5-7cc4-4e3d-900f-dbff37cdc601" | requestAllowed | false      | true           |
      | "b5324d08-5d4b-4b54-9a4a-5d15f30877c1" | requestAllowed | true       | false          |

  Scenario: Update with incorrect scope
    Given the following services exist:
      | databaseId                             | isActive |
      | "a6516e2e-aa11-4ed2-881f-9b0aa2ec9f11" | true     |
    And my scope is "service_catalog:read"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I update the requestAllowed with true in the service where databaseId is "a6516e2e-aa11-4ed2-881f-9b0aa2ec9f11"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Update with incorrect client
    Given the following services exist:
      | databaseId                             | isActive |
      | "d12ba795-bfd6-3f87-ae04-b2864d7fdca1" | true     |
    And my scope is "service_catalog:write"
    And my client type is "MIS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I update the requestAllowed with true in the service where databaseId is "d12ba795-bfd6-3f87-ae04-b2864d7fdca1"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Update non-existent item
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I update the requestAllowed with true in the service where databaseId is "a41ba795-ffd6-af87-1e04-f2864d7fdc22"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item
