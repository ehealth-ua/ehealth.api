Feature: Deactivate medical program

  Scenario: Successful deactivation
    Given the following medical programs exist:
      | databaseId                             |
      | "19f25b9a-d34f-4f12-baaa-c94a8f77c786" |
    And my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "7f4ab7c1-08e6-4fe4-8cd9-25e146bb0061"
    When I deactivate medical program where databaseId is "19f25b9a-d34f-4f12-baaa-c94a8f77c786"
    Then no errors should be returned
    And I should receive requested item
    And the isActive of the requested item should be false

  Scenario: Deactivate when active medical programs exist
    Given the following medical programs exist:
      | databaseId                             |
      | "8d0d25ad-eb91-4a35-ad54-cb20c13d5fc3" |
    And the following program medications exist:
      | databaseId                             | medicalProgramId                       |
      | "62d602dd-7a60-4823-8e69-a950b54b86ca" | "8d0d25ad-eb91-4a35-ad54-cb20c13d5fc3" |
    And my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "a538013e-70e6-4554-83ef-8d2beedbe7b0"
    When I deactivate medical program where databaseId is "8d0d25ad-eb91-4a35-ad54-cb20c13d5fc3"
    Then the "CONFLICT" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect scope
    Given my scope is "medical_program:read"
    And my consumer ID is "1c5a5f67-e228-4580-8887-2fe95ec46be8"
    When I deactivate medical program where databaseId is "e12e2287-b271-4ca1-a523-97aa99eef54f"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate with incorrect client
    Given my scope is "medical_program:write"
    And my client type is "MSP"
    And my consumer ID is "87030ef0-277c-4323-812d-6500506e7ae7"
    When I deactivate medical program where databaseId is "83bb0bd7-5688-49b6-9357-3c538afe0f51"
    Then the "FORBIDDEN" error should be returned
    And I should not receive requested item

  Scenario: Deactivate non-existent item
    Given my scope is "medical_program:write"
    And my client type is "NHS"
    And my consumer ID is "a538013e-70e6-4554-83ef-8d2beedbe7b0"
    When I deactivate medical program where databaseId is "94442d61-3b74-4d70-bf5f-9ea1730937be"
    Then the "NOT_FOUND" error should be returned
    And I should not receive requested item

