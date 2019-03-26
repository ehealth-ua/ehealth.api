Feature: Deactivate employee

  Scenario: Successful deactivation
    Given the following legal entities exist:
      | databaseId                             |
      | "e0edf3a8-646c-4a81-84dd-1d52229f6f0a" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employee_type | status     |
      | "b6640042-c34d-4d61-822d-cc36f3eb30db" | "NHS"         | "APPROVED" |
    And my scope is "employee:write"
    And my client type is "NHS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    And event would be published to event manager
    When I deactivate employee where databaseId is "b6640042-c34d-4d61-822d-cc36f3eb30db"
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "DISMISSED"

  Scenario: Deactivate employee not belonging to current legal entity
    Given the following legal entities exist:
      | databaseId                             |
      | "5045f0bd-e4c9-4fcd-8f8e-89460132df3e" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employee_type | status     |
      | "c20c47ec-9e46-4cb6-b850-8a8ef9f32987" | "NHS"         | "APPROVED" |
    And my scope is "employee:write"
    And my client type is "NHS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate employee where databaseId is "c20c47ec-9e46-4cb6-b850-8a8ef9f32987"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate already deactivated employee
    Given the following legal entities exist:
      | databaseId                             |
      | "e0edf3a8-646c-4a81-84dd-1d52229f6f0a" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employee_type | status      |
      | "ccfb1492-0f12-4365-bb6f-50939ef25319" | "NHS"         | "DISMISSED" |
    And my scope is "employee:write"
    And my client type is "NHS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate employee where databaseId is "ccfb1492-0f12-4365-bb6f-50939ef25319"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect scope
    Given the following legal entities exist:
      | databaseId                             |
      | "e0edf3a8-646c-4a81-84dd-1d52229f6f0a" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employee_type | status      |
      | "28893adf-5c4f-4ba0-8f28-449e8f0648a9" | "NHS"         | "APPROVED" |
    And my scope is "employee:read"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate employee where databaseId is "28893adf-5c4f-4ba0-8f28-449e8f0648a9"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given the following legal entities exist:
      | databaseId                             |
      | "e0edf3a8-646c-4a81-84dd-1d52229f6f0a" |
    And the following employees are associated with legal entities accordingly:
      | databaseId                             | employee_type | status      |
      | "39268305-53f0-4603-bbd4-ee54fbcab37f" | "NHS"         | "DISMISSED" |
    And my scope is "employee:write"
    And my client type is "MIS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate employee where databaseId is "39268305-53f0-4603-bbd4-ee54fbcab37f"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "employee:write"
    And my client type is "NHS"
    And my client ID is "e0edf3a8-646c-4a81-84dd-1d52229f6f0a"
    And my consumer ID is "c3aeae43-985b-4412-b8ff-15ddee5a47de"
    When I deactivate employee where databaseId is "6408ee2e-cbe7-4d74-8353-8c7690b46c58"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item
