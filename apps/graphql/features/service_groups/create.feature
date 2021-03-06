Feature: Create service group

  Scenario Outline: Successful creation
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "1ad3c0e6-e2fc-2d3c-a15c-5101874165a7"
    When I create service group with attributes:
      | name   | code   | parentGroupId     |
      | <name> | <code> | <parent_group_id> |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the name of the requested item should be <name>

    Examples:
      | name                                     | code  | parent_group_id                                                        |
      | "Ультразвукові дослідження в неврології" | "2FA" | null                                                                   |
      | "Ультразвукові дослідження в неврології" | "2FA" | "U2VydmljZUdyb3VwOmY0Y2UzZmRmLWQ0OWItNDI2Yy05NjM2LThiMTg2ZGI3NWQ3Mw==" |

  Scenario: Create with incorrect scope
    Given my scope is "service_catalog:read"
    And my consumer ID is "04796283-74b8-4632-9f7f-9e227ae9426e"
    When I create service group with attributes:
      | name                                     | code  |
      | "Ультразвукові дослідження в неврології" | "2FA" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given my scope is "service_catalog:write"
    And my client type is "MSP"
    And my consumer ID is "089c0204-a191-4537-ab92-56dca268443c"
    When I create service group with attributes:
      | name                                     | code  |
      | "Ультразвукові дослідження в неврології" | "2FA" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "94e4301f-2d28-4403-b59f-b5865e9ca26f"
    When I create service group with attributes:
      | name   | code   |
      | <name> | <code> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | name                           | code  |
      | ""                             | "2FA" |
      | "Діагностичні інструментальні" | ""    |





