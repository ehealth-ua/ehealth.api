Feature: Deactivate service group

  Scenario: Successful deactivation
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "f17f96f5-d5be-4270-8940-a3fe0ddbcd7b"
    Then no errors should be returned
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Deactivate with incorrect scope
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66" | true     |
    And my scope is "service_catalog:read"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "e6516e2e-aa11-4ed2-881f-9b0aa2ec9f66"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "d41aa795-bfd6-4e87-be04-b2864d7fdc44" | true     |
    And my scope is "service_catalog:write"
    And my client type is "MIS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "d41aa795-bfd6-4e87-be04-b2864d7fdc44"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "2abef13c-7b4c-4c83-876f-a269ff816915"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

  Scenario: Deactivate already deactivated service group
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "ccfb1492-0f12-4365-bb6f-50939ef25319" | false    |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate service group where databaseId is "ccfb1492-0f12-4365-bb6f-50939ef25319"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate when active program service exist
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "01bbad75-a695-4f5b-8cc3-657b9ea0a34e" | true     |
    And the following program services are associated with service groups accordingly:
      | isActive |
      | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "01bbad75-a695-4f5b-8cc3-657b9ea0a34e"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate service group when active service exist
    Given the following service groups exist:
      | databaseId                             | isActive |
      | "50a08611-3d72-4e03-96d2-71f11f3dc795" | true     |
    And the following services exist:
      | databaseId                             | isActive |
      | "0ef6d25a-fbd8-4476-8247-057d40230e19" | true     |
    And the following services groups exist:
      | serviceGroupId                         | serviceId                              |
      | "50a08611-3d72-4e03-96d2-71f11f3dc795" | "0ef6d25a-fbd8-4476-8247-057d40230e19" |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "46d29f1b-122c-40ae-a36b-be138fb9c987"
    When I deactivate service group where databaseId is "50a08611-3d72-4e03-96d2-71f11f3dc795"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item
