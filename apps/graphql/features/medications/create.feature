Feature: Create medication

  Scenario Outline: Successful creation
    Given my scope is "medication:write"
    And my client type is "NHS"
    And my consumer ID is "1ad3c0e6-e2fc-2d3c-a15c-5101874165a7"
    And the following INNM dosages exist:
      | databaseId        |
      | <innmDosageId>  |
    When I create medication with attributes:
      | name   | atcCodes   | certificate   | certificateExpiredAt   | container   | dailyDosage   | form   | ingredients   | manufacturer   | packageMinQty   | packageQty   |
      | <name> | <atcCodes> | <certificate> | <certificateExpiredAt> | <container> | <dailyDosage> | <form> | <ingredients> | <manufacturer> | <packageMinQty> | <packageQty> |
    Then no errors should be returned
    And request id should be returned
    And I should receive requested item
    And the name of the requested item should be <name>

    Examples:
      | name      | innmDosageId                           | atcCodes               | certificate | certificateExpiredAt | container                                                                                         | dailyDosage | form                           | ingredients                                                                                                                                                                                    | manufacturer                        | packageMinQty | packageQty |
      | "Ниферон" | "01c9b8ae-fe41-4390-8f3c-4744f5b13717" | ["C08CA01", "C08CA02"] | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 50} | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |

  Scenario: Create with incorrect scope
    Given my scope is "medication:read"
    And my consumer ID is "04796283-74b8-4632-9f7f-9e227ae9426e"
    When I create medication with attributes:
      | name      | atcCodes               | certificate | certificateExpiredAt | container                                                                                         | dailyDosage | form                           | ingredients                                                                                                                                                                                    | manufacturer                        | packageMinQty | packageQty |
      | "Ниферон" | ["C08CA01", "C08CA02"] | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 50} | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario: Create with incorrect client
    Given my scope is "medication:write"
    And my client type is "MSP"
    And my consumer ID is "089c0204-a191-4537-ab92-56dca268443c"
    When I create medication with attributes:
      | name      | atcCodes               | certificate | certificateExpiredAt | container                                                                                         | dailyDosage | form                           | ingredients                                                                                                                                                                                    | manufacturer                        | packageMinQty | packageQty |
      | "Ниферон" | ["C08CA01", "C08CA02"] | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 50} | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |
    Then the "FORBIDDEN" error should be returned
    And request id should be returned
    And I should not receive requested item

  Scenario Outline: Create with invalid params
    Given my scope is "medication:write"
    And my client type is "NHS"
    And my consumer ID is "94e4301f-2d28-4403-b59f-b5865e9ca26f"
    When I create medication with attributes:
      | name   | atcCodes   | certificate   | certificateExpiredAt   | container   | dailyDosage   | form   | ingredients   | manufacturer   | packageMinQty   | packageQty   |
      | <name> | <atcCodes> | <certificate> | <certificateExpiredAt> | <container> | <dailyDosage> | <form> | <ingredients> | <manufacturer> | <packageMinQty> | <packageQty> |
    Then the "UNPROCESSABLE_ENTITY" error should be returned
    And request id should be returned
    And I should not receive requested item

    Examples:
      | name      | innmDosageId                           | atcCodes               | certificate | certificateExpiredAt | container                                                                                          | dailyDosage | form                           | ingredients                                                                                                                                                                                    | manufacturer                        | packageMinQty | packageQty |
      | "Ниферон" | "01c9b8ae-fe41-4390-8f3c-4744f5b13717" | ["INVALID"]            | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 50}  | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |
      | "Ниферон" | "01c9b8ae-fe41-4390-8f3c-4744f5b13717" | ["C08CA01", "C08CA02"] | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 50}  | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |
      | "Ниферон" | "01c9b8ae-fe41-4390-8f3c-4744f5b13717" | ["C08CA01", "C08CA02"] | "100-fA-11" | "2019-12-12"         | {"numerator_unit": "ML", "numerator_value": 1, "denumerator_unit": "MKG", "denumerator_value": 50} | 0.02        | "AEROSOL_FOR_INHALATION_DOSED" | [{"innmDosageId": "01c9b8ae-fe41-4390-8f3c-4744f5b13717", "dosage": {"numerator_unit": "DOSE", "numerator_value": 1, "denumerator_unit": "ML", "denumerator_value": 100}, "is_primary": true}] | {"name": "Bayer", "country": "GER"} | 1             | 5          |
