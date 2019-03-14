Feature: Deactivate medication

  Scenario: Successful deactivation
    Given the following medications exist:
      | databaseId                             | isActive |
      | "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b" | true     |
    And my scope is "medication:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate medication where databaseId is "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b"
    Then no errors should be returned
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Deactivate when active program medications exist
    Given the following medications exist:
      | databaseId                             | isActive |
      | "01bbad75-a695-4f5b-8cc3-657b9ea0a34e" | true     |
    And the following program medications exist:
      | medicationId                           | isActive |
      | "01bbad75-a695-4f5b-8cc3-657b9ea0a34e" | true     |
    And my scope is "medication:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate medication where databaseId is "01bbad75-a695-4f5b-8cc3-657b9ea0a34e"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect scope
    Given the following medications exist:
      | databaseId                             | isActive |
      | "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66" | true     |
    And my scope is "medication:read"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate medication where databaseId is "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given the following medications exist:
      | databaseId                             | isActive |
      | "d41aa795-bfd6-4e87-be04-b2864d7fdc44" | true     |
    And my scope is "medication:write"
    And my client type is "MIS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate medication where databaseId is "d41aa795-bfd6-4e87-be04-b2864d7fdc44"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "medication:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate medication where databaseId is "2abef13c-7b4c-4c83-876f-a269ff816915"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item
