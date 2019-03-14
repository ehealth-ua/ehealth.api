Feature: Deactivate INNM dosage

  Scenario: Successful deactivation
    Given the following INNM dosages exist:
      | databaseId                             | isActive |
      | "4a3cc729-451c-41cc-accc-e89f658936aa" | true     |
    And my scope is "innm_dosage:write"
    And my client type is "NHS"
    And my consumer ID is "908c5248-e8a9-438c-8e94-be45ee240aaf"
    When I deactivate INNM dosage where databaseId is "4a3cc729-451c-41cc-accc-e89f658936aa"
    Then no errors should be returned
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Deactivate when active medications exist
    Given the following INNM dosages exist:
      | databaseId                             | isActive |
      | "9ccbe6e1-d5d9-43ca-a2ee-d121c49c289d" | true     |
    And the following medications exist:
      | databaseId                             | isActive |
      | "71d847f6-38c3-48a9-baa2-ce6b0eabc20e" | true     |
    And the following medication ingredients exist:
      | medicationChildId                      | parentId                               | isPrimary |
      | "9ccbe6e1-d5d9-43ca-a2ee-d121c49c289d" | "71d847f6-38c3-48a9-baa2-ce6b0eabc20e" | true      |
    And my scope is "innm_dosage:write"
    And my client type is "NHS"
    And my consumer ID is "908c5248-e8a9-438c-8e94-be45ee240aaf"
    When I deactivate INNM dosage where databaseId is "9ccbe6e1-d5d9-43ca-a2ee-d121c49c289d"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect scope
    Given the following INNM dosages exist:
      | databaseId                             | isActive |
      | "e885b46b-0c26-4b2a-be8b-4cdbcbfc2f63" | true     |
    And my scope is "innm_dosage:read"
    And my consumer ID is "908c5248-e8a9-438c-8e94-be45ee240aaf"
    When I deactivate INNM dosage where databaseId is "e885b46b-0c26-4b2a-be8b-4cdbcbfc2f63"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given the following INNM dosages exist:
      | databaseId                             | isActive |
      | "18772d82-8bbc-432b-9f69-b84833370174" | true     |
    And my scope is "innm_dosage:write"
    And my client type is "MIS"
    And my consumer ID is "908c5248-e8a9-438c-8e94-be45ee240aaf"
    When I deactivate INNM dosage where databaseId is "18772d82-8bbc-432b-9f69-b84833370174"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "innm_dosage:write"
    And my client type is "NHS"
    And my consumer ID is "908c5248-e8a9-438c-8e94-be45ee240aaf"
    When I deactivate INNM dosage where databaseId is "57b4346f-0769-47c1-9675-8cc5124e9e30"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

