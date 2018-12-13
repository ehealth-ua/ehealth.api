Feature: Get all reimbursement contracts

  Scenario: Request all items with NHS client
    Given there are 2 reimbursement contracts exist
    And there are 10 capitation contracts exist
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 reimbursement contracts
    Then no errors should be returned
    And I should receive collection with 2 items
