Feature: Suspend reimbursement contract
  
  Scenario Outline: Success on suspend reimbursement contract
    Given the following reimbursement contracts exist:
      | databaseId   |
      | <database_id> |
    And the following dictionaries exist:
      | name                     | values                                                                                         |
      | "CONTRACT_STATUS_REASON" | {"DEFAULT": "label 1", "AUTO_EXPIRED": "label 2", "AUTO_DEACTIVATION_LEGAL_ENTITY": "label 3"} |
    And my consumer ID is <consumer_id>
    And my scope is "contract:update"
    And my client type is "NHS"
    When I suspend reimbursement contract where databaseId is <database_id>
    Then no errors should be returned
    And I should receive requested item
    And the statusReason of the requested item should be "DEFAULT"
    And the isSuspended of the requested item should be true
    And the reason of the requested item should be "Custom reason"
    And event manager has event for ReimbursementContract with ID <database_id> and consumer ID <consumer_id>
  
  Examples:
      | database_id                            | consumer_id                            |
      | "1e712d60-b74b-4cf9-839b-6c895b88deb4" | "afd3c0e6-e2fc-4d3c-a15c-5101874165d8" |

  Scenario: Request with incorrect client type
    Given my scope is "contract:update"
    And my client type is "MIS"
    When I suspend reimbursement contract where databaseId is "5bb4d2c6-c5d8-4965-9314-553ee5cfe038"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Request with wrong scope
    Given the following reimbursement contracts exist:
      | databaseId                             |
      | "cf65f6a7-6e6d-4517-b75c-fca679f09583" |
    When I suspend reimbursement contract where databaseId is "cf65f6a7-6e6d-4517-b75c-fca679f09583"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario Outline: Fails with entity attributtes conflicts
    Given the following reimbursement contracts exist:
      | databaseId    | status   | isSuspended    | endDate   |
      | <database_id> | <status> | <is_suspended> | <end_date> |
    And the following dictionaries exist:
      | name                     | values                                                                                         |
      | "CONTRACT_STATUS_REASON" | {"DEFAULT": "label 1", "AUTO_EXPIRED": "label 2", "AUTO_DEACTIVATION_LEGAL_ENTITY": "label 3"} |
    And my consumer ID is "afd3c0e6-e2fc-4d3c-a15c-5101874165d8"
    And my scope is "contract:update"
    And my client type is "NHS"
    When I suspend reimbursement contract where databaseId is <database_id>
    Then the "CONFLICT" error should be returned
    And I should not receive requested item
    
    Examples:
      | database_id                            | status       | is_suspended | end_date     |
      | "3b1a0ad5-7cc4-4e3d-900f-dbff37cdc601" | "VERIFIED"   | true         | "2200-01-01" |
      | "b5324d08-5d4b-4b54-9a4a-5d15f30877c1" | "TERMINATED" | false        | "2200-01-01" |
      | "4e143681-cb51-4543-b59a-f02592a0d021" | "VERIFIED"   | false        | "1900-01-01" |

