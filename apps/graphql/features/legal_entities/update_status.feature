Feature: Update legal entity status

  Scenario Outline: Successful status update
    Given the following legal entities exist:
      | databaseId                             | status        |
      | "28be7794-65e4-4152-8e13-2bea0a5f0581" | <prev_status> |
    And my scope is "legal_entity:update"
    And my consumer ID is "c7a4fc97-96fe-4224-9037-ba6a89e6973a"
    And event would be published to event manager
    When I update the status to <next_status> with reason "Because I can." in legal entity where databaseId is "28be7794-65e4-4152-8e13-2bea0a5f0581"
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be <next_status>
    And the statusReason of the requested item should be "MANUAL_LEGAL_ENTITY_STATUS_UPDATE"

    Examples:
      | prev_status | next_status |
      | "ACTIVE"    | "SUSPENDED" |
      | "SUSPENDED" | "ACTIVE"    |

  Scenario: Successful suspension with active contracts
    Given the following legal entities exist:
      | databaseId                             | status   |
      | "28be7794-65e4-4152-8e13-2bea0a5f0581" | "ACTIVE" |
    And the following capitation contracts exist:
      | databaseId                             | status     | isSuspended | contractorLegalEntityId                |
      | "495e40c9-5db8-403c-b989-6c09d14469b4" | "VERIFIED" | false       | "28be7794-65e4-4152-8e13-2bea0a5f0581" |
    And my scope is "legal_entity:update"
    And my consumer ID is "c7a4fc97-96fe-4224-9037-ba6a89e6973a"
    And event would be published to event manager
    When I update the status to "SUSPENDED" with reason "Because I can." in legal entity where databaseId is "28be7794-65e4-4152-8e13-2bea0a5f0581"
    Then no errors should be returned
    And I should receive requested item
    And the status of the requested item should be "SUSPENDED"
    And the isSuspended of the capitation contract where databaseId is "495e40c9-5db8-403c-b989-6c09d14469b4" should be true

  Scenario Outline: Update status with incorrect transition
    Given the following legal entities exist:
      | databaseId                             | status        |
      | "28be7794-65e4-4152-8e13-2bea0a5f0581" | <prev_status> |
    And my scope is "legal_entity:update"
    And my consumer ID is "c7a4fc97-96fe-4224-9037-ba6a89e6973a"
    When I update the status to <next_status> with reason "Because I can." in legal entity where databaseId is "28be7794-65e4-4152-8e13-2bea0a5f0581"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

    Examples:
      | prev_status | next_status |
      | "CLOSED"    | "ACTIVE"    |
      | "ACTIVE"    | "ACTIVE"    |

  Scenario: Update status with incorrect scope
    Given the following legal entities exist:
      | databaseId                             | status   |
      | "28be7794-65e4-4152-8e13-2bea0a5f0581" | "ACTIVE" |
    And my scope is "legal_entity:read"
    And my consumer ID is "c7a4fc97-96fe-4224-9037-ba6a89e6973a"
    When I update the status to "SUSPENDED" with reason "Because I can." in legal entity where databaseId is "28be7794-65e4-4152-8e13-2bea0a5f0581"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item
