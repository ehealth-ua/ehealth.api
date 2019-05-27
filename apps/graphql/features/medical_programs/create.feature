Feature: Create medical program

  Scenario Outline: Successful creation
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "afd3c0e6-e2fc-4d3c-a15c-5101874165d8"
    And the following dictionaries exist:
      | name                     | values                                             |
      | "MEDICAL_PROGRAM_TYPE"   | {"MEDICATION": "medication", "SERVICE": "service"} |
    When I create medical program with attributes:
      | name   | type   |
      | <name> | <type> |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the name of the requested item should be <name>
    And the type of the requested item should be <type>

    Examples:
      | name                 | type         |
      | "Доступні ліки"      | "MEDICATION" |
      | "УЗІ в кожну родину" | "SERVICE"    |

  Scenario: Create with read scope
    Given my scope is "medical_program:read"
    And my consumer ID is "301053aa-3f49-4db2-8f76-fd9df60e78c7"
    And the following dictionaries exist:
      | name                     | values                                             |
      | "MEDICAL_PROGRAM_TYPE"   | {"MEDICATION": "medication", "SERVICE": "service"} |
    When I create medical program with attributes:
      | name                 | type         |
      | "Доступні ліки"      | "MEDICATION" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with MSP client
    Given my scope is "medical_program:write"
    And my client type is "MSP"
    And my consumer ID is "87030ef0-277c-4323-812d-6500506e7ae7"
    And the following dictionaries exist:
      | name                     | values                                             |
      | "MEDICAL_PROGRAM_TYPE"   | {"MEDICATION": "medication", "SERVICE": "service"} |
    When I create medical program with attributes:
      | name                 | type         |
      | "Доступні ліки"      | "MEDICATION" |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "13366228-25dd-2f71-4a2b-e8641e1645ac"
    And the following dictionaries exist:
      | name                     | values                                             |
      | "MEDICAL_PROGRAM_TYPE"   | {"MEDICATION": "medication", "SERVICE": "service"} |
    When I create medical program with attributes:
      | name   | type   |
      | <name> | <type> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | type         | name            |
      |              | "Доступні ліки" |
      | "MEDICATION" |                 |
      | "INVALID"    | "Доступні ліки" |
      | "MEDICATION" |"TooLongNamezzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
