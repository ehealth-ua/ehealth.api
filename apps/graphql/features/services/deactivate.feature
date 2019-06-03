Feature: Deactivate service

  Scenario: Successful deactivation
    Given the following services exist:
      | databaseId                             | isActive |
      | "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b"
    Then no errors should be returned
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Successful deactivate when active service group exist
    Given the following services exist:
      | databaseId                             | isActive |
      | "f17f96f5-d5be-4270-8940-a3fe021aba14" | true     |
    And the following service group exist:
      | databaseId                             | isActive |
      | "ab1bad75-4ed2-4f5b-a695-a3fe0ddbcd7b" | true     |
    And the following services groups exist:
      | serviceId                              | serviceGroupId                         |
      | "f17f96f5-d5be-4270-8940-a3fe021aba14" | "ab1bad75-4ed2-4f5b-a695-a3fe0ddbcd7b" |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "f17f96f5-d5be-4270-8940-a3fe021aba14"
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Deactivate when active program services exist
    Given the following program service exist:
      | databaseId                             | isActive |
      | "ab1bad75-b695-115b-2ac3-127b9ea0a3aa" | true     |
    And the following service are associated with program service accordingly:
      | databaseId                             | isActive |
      | "01bbad75-a695-4f5b-8cc3-657b9ea0a34e" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "01bbad75-a695-4f5b-8cc3-657b9ea0a34e"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect scope
    Given the following services exist:
      | databaseId                             | isActive |
      | "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66" | true     |
    And my scope is "service_catalog:read"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given the following services exist:
      | databaseId                             | isActive |
      | "d41aa795-bfd6-4e87-be04-b2864d7fdc44" | true     |
    And my scope is "service_catalog:write"
    And my client type is "MIS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "d41aa795-bfd6-4e87-be04-b2864d7fdc44"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service where databaseId is "2abef13c-7b4c-4c83-876f-a269ff816915"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

  Scenario: Deactivate already deactivated service
    Given the following services exist:
      | databaseId                             | isActive |
      | "ccfb1492-0f12-4365-bb6f-50939ef25319" | false    |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my client ID is "a1edf3a8-646c-2afa-f21d-2d52229f6f1f"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate service where databaseId is "ccfb1492-0f12-4365-bb6f-50939ef25319"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item
