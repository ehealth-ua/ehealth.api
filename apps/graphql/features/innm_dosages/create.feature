Feature: Create INNM Dosage

  Scenario Outline: Successful creation
    Given the following INNMs exist:
      | databaseId |
      | <innm_id>  |
    And my scope is "innm_dosage:write"
    And my client type is "NHS"
    And my consumer ID is "1820f96c-7565-4afa-8705-869439785822"
    When I create INNM dosage with attributes:
      | name   | form   | ingredients   |
      | <name> | <form> | <ingredients> |
    Then no errors should be returned
    And I should receive requested item
    And the name of the requested item should be <name>
    And the form of the requested item should be <form>

    Examples:
      | name            | form            | innm_id                                | ingredients                                                                                                                                                                                             |
      | "Спіронолактон" | "TABLET"        | "d7c7b7d9-be0a-454f-874f-18354af1aaee" | [{"is_primary": true, "innm_id": "SU5OTTpkN2M3YjdkOS1iZTBhLTQ1NGYtODc0Zi0xODM1NGFmMWFhZWU=", "dosage": {"numeratorUnit": "MG", "numeratorValue": 1, "denumeratorUnit": "ML", "denumeratorValue": 2}}]   |
      | "Метформін"     | "COATED_TABLET" | "703baaf5-8d30-47c5-a36e-606b368db274" | [{"is_primary": true, "innm_id": "SU5OTTo3MDNiYWFmNS04ZDMwLTQ3YzUtYTM2ZS02MDZiMzY4ZGIyNzQ=", "dosage": {"numeratorUnit": "MG", "numeratorValue": 8, "denumeratorUnit": "MG", "denumeratorValue": 18}}] |

  Scenario: Create with incorrect scope
    Given my scope is "innm_dosage:read"
    And my consumer ID is "a5e6d8a6-20b9-4858-b20c-dcc770f14134"
    When I create INNM dosage with attributes:
      | name        | form     | ingredients |
      | "Метформін" | "TABLET" | []          |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given my scope is "innm_dosage:write"
    And my client type is "MSP"
    And my consumer ID is "2d90932f-60b1-4103-974b-e51173c85ecc"
    When I create INNM dosage with attributes:
      | name        | form     | ingredients |
      | "Метформін" | "TABLET" | []          |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "innm_dosage:write"
    And my client type is "NHS"
    And my consumer ID is "37587a76-9e11-410c-beda-415dace20f70"
    When I create INNM dosage with attributes:
      | name   | form   | ingredients   |
      | <name> | <form> | <ingredients> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | name        | form     | ingredients                                                                                                                                                                                             |
      | "Метформін" | "TABLET" | []                                                                                                                                                                                                      |
      | "Метформін" | "TABLET" | [{"is_primary": true, "innm_id": "SU5OTTo3MDNiYWFmNS04ZDMwLTQ3YzUtYTM2ZS02MDZiMzY4ZGIyNzU=", "dosage": {"numeratorUnit": "MG", "numeratorValue": 8, "denumeratorUnit": "MG", "denumeratorValue": 18}}]  |
      | "Метформін" | "TABLET" | [{"is_primary": false, "innm_id": "SU5OTTo3MDNiYWFmNS04ZDMwLTQ3YzUtYTM2ZS02MDZiMzY4ZGIyNzU=", "dosage": {"numeratorUnit": "MG", "numeratorValue": 8, "denumeratorUnit": "MG", "denumeratorValue": 18}}] |
