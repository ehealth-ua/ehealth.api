Feature: Get all capitation contracts

  Scenario: Request all capitation contracts with NHS client
    Given there are 2 capitation contracts exist
    And there are 10 reimbursement contracts exist
    And my scope is "contract:read"
    And my client type is "NHS"
    When I request first 10 capitation contracts
    Then no errors should be returned
    And I should receive collection with 2 items
