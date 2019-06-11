Feature: Create service

  Scenario Outline: Successful creation
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I create service with attributes:
      | name   | category   | code   | isComposition   | requestAllowed   |
      | <name> | <category> | <code> | <isComposition> | <requestAllowed> |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the name of the requested item should be <name>
    And the code of the requested item should be <code>
    And the category of the requested item should be <category>
    And the isComposition of the requested item should be <isComposition>
    And the requestAllowed of the requested item should be <requestAllowed>

    Examples:
      | name              | category               | code     | isComposition | requestAllowed |
      | "Нейросонографія" | "laboratory_procedure" | "AF2 01" | false         | true           |

  Scenario: Successful creation with deactivated existing code
    Given the following services exist:
      | code     | isActive |
      | "AF2 01" | false    |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I create service with attributes:
      | name              | category               | code     | isComposition | requestAllowed |
      | "Нейросонографія" | "laboratory_procedure" | "AF2 01" | false         | true           |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the code of the requested item should be "AF2 01"

  Scenario: Create with incorrect scope
    Given my scope is "service_catalog:read"
    And my consumer ID is "04796283-74b8-4632-9f7f-9e227ae9426e"
    And the following dictionaries exist:
      | name               | values                                          |
      | "SERVICE_CATEGORY" | {"laboratory_procedure": "Лабораторні послуги"} |
    When I create service with attributes:
      | name              | category              | code     | isComposition |
      | "Нейросонографія" | "laboratory_procedure"| "AF2 01" | true          |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given my scope is "service_catalog:write"
    And my client type is "MSP"
    And my consumer ID is "089c0204-a191-4537-ab92-56dca268443c"
    And the following dictionaries exist:
      | name               | values                                          |
      | "SERVICE_CATEGORY" | {"laboratory_procedure": "Лабораторні послуги"} |
    When I create service with attributes:
      | name              | category    | code     | isComposition |
      | "Нейросонографія" | "education" | "AF2 01" | true         |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    And the following dictionaries exist:
      | name               | values                                                               |
      | "SERVICE_CATEGORY" | {"imaging": "Послуги з аналізу та інтерпретації медичних зображень"} |
    When I create service with attributes:
      | name   | category   | code   | isComposition   |
      | <name> | <category> | <code> | <isComposition> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | name              | category    | code  | isComposition |
      | "Нейросонографія" | "education" | "000" | false         |
      | "Нейросонографія" | "imaging"   | ""    | false         |
      | ""                | "education" | "123" | false         |

  Scenario: Create with already existing code
    Given the following services exist:
      | code     | isActive |
      | "AF2 01" | true     |
    And my scope is "service_catalog:write"
    And my client type is "NHS"
    And my consumer ID is "8341b7d6-f9c7-472a-960c-7da953cc4ea4"
    When I create service with attributes:
      | name              | category               | code     | isComposition | requestAllowed |
      | "Нейросонографія" | "laboratory_procedure" | "AF2 01" | true          | true           |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item
