Feature: Create INNM

  Scenario Outline: Successful creation
    Given my scope is "innm:write"
    And my client type is "NHS"
    And my consumer ID is "ae9ebf73-ec29-492c-9eb8-8ada2425eab2"
    When I create INNM with attributes:
      | name   | name_original   | sctid   |
      | <name> | <name_original> | <sctid> |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the name of the requested item should be <name>
    And the name_original of the requested item should be <name_original>

    Examples:
      | name         | name_original   | sctid      |
      | "Диэтиламид" | "Diethylamide"  | "10050090" |
      | "Этивон"     | "Etivon"        | "22233111" |

  Scenario: Create with incorrect scope
    Given my scope is "innm:read"
    And my consumer ID is "5aa32f90-8626-4e3e-bd4d-a9db5e9436b2"
    When I create INNM with attributes:
      | name         | name_original   | sctid      |
      | "Диэтиламид" | "Diethylamide"  | "10050090" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given my scope is "innm:write"
    And my client type is "MSP"
    And my consumer ID is "b329ce3c-bf26-48a1-b042-22ca91905d0c"
    When I create INNM with attributes:
      | name         | name_original  | sctid      |
      | "Диэтиламид" | "Diethylamide" | "10050090" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "innm:write"
    And my client type is "NHS"
    And my consumer ID is "08866228-03dd-4f72-9a2b-e8641e1602ae"
    When I create INNM with attributes:
      | name   | name_original   | sctid   |
      | <name> | <name_original> | <sctid> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | name         | name_original   | sctid      |
      |              | "Diethylamide"  | "10050090" |
      | "Диэтиламид" |                 | "10050090" |
      | "Этивон"     | "Etivon"        |            |
      | "Этивон"     | "Etivon"        | "invalid"  |
      | "Этивон"     | "Этивон"        | "10050090" |
      | "Etivon"     | "Etivon"        | "10050090" |