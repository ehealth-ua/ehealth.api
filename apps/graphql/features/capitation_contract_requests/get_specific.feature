Feature: Get specific capitation contract request

  Scenario: Request with NHS client
    Given the following capitation contract requests exist:
      | databaseId                             |
      | "f776b681-2c08-4acd-a0fe-5e4f05af96d0" |
    And my scope is "contract_request:read"
    And my client type is "NHS"
    When I request capitation contract request where databaseId is "f776b681-2c08-4acd-a0fe-5e4f05af96d0"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "f776b681-2c08-4acd-a0fe-5e4f05af96d0"

  Scenario: Request belonging item with MSP client
    Given the following legal entities exist:
      | databaseId                             | type   |
      | "2864c3be-1e64-4657-a08b-c95ac83ace2a" | "MSP"  |
    And the following capitation contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "a473c9bb-0da3-4ba9-863a-da1b0ae7080e" | "2864c3be-1e64-4657-a08b-c95ac83ace2a" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    And my client ID is "2864c3be-1e64-4657-a08b-c95ac83ace2a"
    When I request capitation contract request where databaseId is "a473c9bb-0da3-4ba9-863a-da1b0ae7080e"
    Then no errors should be returned
    And I should receive requested item
    And the databaseId of the requested item should be "a473c9bb-0da3-4ba9-863a-da1b0ae7080e"

  Scenario: Request not belonging item with MSP client
    Given the following legal entities exist:
      | databaseId                             | type  |
      | "b2d44ab8-1bf7-43d5-b46f-426c29a7c693" | "MSP" |
      | "32782d19-3a7e-4434-be61-803622e1f86c" | "MSP" |
    And the following capitation contract requests exist:
      | databaseId                             | contractorLegalEntityId                |
      | "aa111175-ac68-4185-acd0-5b954aaea9ef" | "32782d19-3a7e-4434-be61-803622e1f86c" |
    And my scope is "contract_request:read"
    And my client type is "MSP"
    And my client ID is "b2d44ab8-1bf7-43d5-b46f-426c29a7c693"
    When I request capitation contract request where databaseId is "aa111175-ac68-4185-acd0-5b954aaea9ef"
    Then no errors should be returned
    And I should not receive requested item

  Scenario: Request with incorrect client
    Given the following capitation contract requests exist:
      | databaseId                             |
      | "f1cd2866-d9fb-4d80-9739-73231304ffa7" |
    And my scope is "contract_request:read"
    And my client type is "MIS"
    When I request capitation contract request where databaseId is "f1cd2866-d9fb-4d80-9739-73231304ffa7"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item
