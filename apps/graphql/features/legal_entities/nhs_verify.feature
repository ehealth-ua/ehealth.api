Feature: Verify legal entity by NHS

  Scenario Outline: Successful verification
    Given the following legal entities exist:
      | databaseId                             | status   | nhsReviewed | nhsVerified         | nhsUnverifiedAt          |
      | "1be802e4-94af-498c-a94f-855f78044979" | "ACTIVE" | true        | <prev_nhs_verified> | <prev_nhs_unverified_at> |
    And my scope is "legal_entity:nhs_verify"
    And my client ID is "02656267-c2db-46ad-916e-ed8317e41d05"
    When I verify by NHS with <next_nhs_verified> legal entity where databaseId is "1be802e4-94af-498c-a94f-855f78044979"
    Then no errors should be returned
    And I should receive requested item
    And the nhsVerified of the requested item should be <next_nhs_verified>
    And the nhsUnverifiedAt of the requested item should be <next_nhs_unverified_at>

    Examples:
      | prev_nhs_verified | prev_nhs_unverified_at        | next_nhs_verified | next_nhs_unverified_at |
      | false             | "2019-05-14T20:39:50.000000Z" | true              | null                   |
      | true              | null                          | false             | not null               |

  Scenario: Verify inactive legal entity
    Given the following legal entities exist:
      | databaseId                             | status      | nhsReviewed | nhsVerified | nhsUnverifiedAt               |
      | "1be802e4-94af-498c-a94f-855f78044979" | "SUSPENDED" | true        | false       | "2019-05-14T20:39:50.000000Z" |
    And my scope is "legal_entity:nhs_verify"
    And my client ID is "02656267-c2db-46ad-916e-ed8317e41d05"
    When I verify by NHS with true legal entity where databaseId is "1be802e4-94af-498c-a94f-855f78044979"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Verify already verified legal entity
    Given the following legal entities exist:
      | databaseId                             | status   | nhsReviewed | nhsVerified | nhsUnverifiedAt |
      | "1be802e4-94af-498c-a94f-855f78044979" | "ACTIVE" | true        | true        | null            |
    And my scope is "legal_entity:nhs_verify"
    And my client ID is "02656267-c2db-46ad-916e-ed8317e41d05"
    When I verify by NHS with true legal entity where databaseId is "1be802e4-94af-498c-a94f-855f78044979"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Verify not reviewed legal entity
    Given the following legal entities exist:
      | databaseId                             | status   | nhsReviewed | nhsVerified | nhsUnverifiedAt               |
      | "1be802e4-94af-498c-a94f-855f78044979" | "ACTIVE" | false       | false       | "2019-05-14T20:39:50.000000Z" |
    And my scope is "legal_entity:nhs_verify"
    And my client ID is "02656267-c2db-46ad-916e-ed8317e41d05"
    When I verify by NHS with true legal entity where databaseId is "1be802e4-94af-498c-a94f-855f78044979"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Verify with incorrect scope
    Given the following legal entities exist:
      | databaseId                             | status   | nhsReviewed | nhsVerified | nhsUnverifiedAt               |
      | "1be802e4-94af-498c-a94f-855f78044979" | "ACTIVE" | true        | false       | "2019-05-14T20:39:50.000000Z" |
    And my scope is "legal_entity:read"
    And my client ID is "02656267-c2db-46ad-916e-ed8317e41d05"
    When I verify by NHS with true legal entity where databaseId is "1be802e4-94af-498c-a94f-855f78044979"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item
