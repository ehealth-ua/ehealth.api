Feature: Create medical program

  Scenario: Successful creation of a medical program
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "afd3c0e6-e2fc-4d3c-a15c-5101874165d8"
    When I create medical program with name "Доступні ліки"
    Then no errors should be returned
    And I should receive requested item
    And the name of the requested item should be "Доступні ліки"

  Scenario: Create medical program with read scope
    Given my scope is "medical_program:read"
    And my consumer ID is "301053aa-3f49-4db2-8f76-fd9df60e78c7"
    When I create medical program with name "Доступні ліки"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Create medical program with MSP client
    Given my scope is "medical_program:write"
    And my client type is "MSP"
    And my consumer ID is "87030ef0-277c-4323-812d-6500506e7ae7"
    When I create medical program with name "Доступні ліки"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Create medical program with empty name
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "a538013e-70e6-4554-83ef-8d2beedbe7b0"
    When I create medical program with name " "
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And I should not receive requested item

  Scenario: Create medical program with too long name
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "a538013e-70e6-4554-83ef-8d2beedbe7b0"
    When I create medical program with name "TooLongNamezzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz"
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And I should not receive requested item

