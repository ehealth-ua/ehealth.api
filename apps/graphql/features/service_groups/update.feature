Feature: Update service group

  Scenario Outline: Successful update
    Given the following service groups exist:
      | databaseId    | requestAllowed    |
      | <database_id> | <request_allowed> |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "e2c24b94-beb6-4522-b3a9-9eb4f0b42d9e"
    When I update the <field> with <next_value> in the service group where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the <field> of the requested item should be <next_value>

    Examples:
      | database_id                            | field          | next_value | request_allowed |
      | "2c14b0cf-00cb-4807-ada0-e73ad13f0d8a" | requestAllowed | false      | true            |
      | "fd4318ea-f90a-485c-ad63-897ee769d089" | requestAllowed | true       | false           |

  Scenario: Update with incorrect scope
    Given the following service groups exist:
      | databaseId                             | requestAllowed |
      | "035d637f-ec30-4a3d-89ac-d0f53fb67f9a" | false          |
    And my scope is "service_catalog:read"
    And my consumer ID is "e2c24b94-beb6-4522-b3a9-9eb4f0b42d9e"
    When I update the requestAllowed with true in the service group where databaseId is "035d637f-ec30-4a3d-89ac-d0f53fb67f9a"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Update with incorrect client
    Given the following service groups exist:
      | databaseId                             | requestAllowed |
      | "035d637f-ec30-4a3d-89ac-d0f53fb67f9a" | false          |
    And my scope is "service_catalog:write"
    And my client type is "MIS"
    And my consumer ID is "e2c24b94-beb6-4522-b3a9-9eb4f0b42d9e"
    When I update the requestAllowed with true in the service group where databaseId is "035d637f-ec30-4a3d-89ac-d0f53fb67f9a"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Update non-existent item
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "e2c24b94-beb6-4522-b3a9-9eb4f0b42d9e"
    When I update the requestAllowed with true in the service group where databaseId is "035d637f-ec30-4a3d-89ac-d0f53fb67f9a"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item
